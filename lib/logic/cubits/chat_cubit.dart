import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../data/repositories/chat_repositories.dart';
part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;
  final String chatId;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  ChatCubit(this._repository, this.chatId) : super(ChatInitial());

  void loadMessages() async {
    try {
      emit(ChatLoading());

      ChatModel? chat;
      for (int i = 0; i < 3; i++) {
        try {
          chat = await _repository.getChatDetails(chatId);
          break;
        } catch (e) {
          if (i == 2) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      // وضع علامة على الرسائل كمسلمة ومقروءة عند فتح المحادثة
      await _repository.markMessagesAsDelivered(chatId, userId);
      await _repository.markMessagesAsRead(chatId, userId);

      _messagesSubscription?.cancel();
      final messagesStream = _repository.getMessages(chatId);
      _messagesSubscription = messagesStream.listen(
        (messages) async {
          if (!isClosed) {
            // تحديث حالة الإيصال والقراءة للرسائل الجديدة عند وصولها
            final hasNewMessages = messages.any((msg) => 
              msg.receiverId == userId && (!msg.isDelivered || !msg.isRead));
            
            if (hasNewMessages) {
              // تمييز الرسائل الجديدة بالتسليم والقراءة
              await _repository.markMessagesAsDelivered(chatId, userId);
              await _repository.markMessagesAsRead(chatId, userId);
            }
            
            emit(ChatLoaded(messages: messages, chat: chat!));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(ChatError('حدث خطأ أثناء جلب الرسائل: $error'));
            print('Error loading messages: $error');
          }
        },
      );
      
      // إنشاء مؤقت لتحديث حالة الرسائل كل 5 ثوانٍ
      Timer.periodic(Duration(seconds: 5), (timer) async {
        if (isClosed) {
          timer.cancel();
          return;
        }
        
        if (state is ChatLoaded) {
          // تحديث حالة التسليم والقراءة دوريًا
          await _repository.markMessagesAsDelivered(chatId, userId);
          await _repository.markMessagesAsRead(chatId, userId);
        }
      });
      
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('حدث خطأ: $e'));
        print('Error loading chat: $e');
      }
    }
  }

  void sendMessage(String content, {String? imageUrl, String? audioUrl, String? replyTo}) async {
    try {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final receiverId = currentState.chat.participants.firstWhere(
              (id) => id != userId,
        );

        final tempMessage = MessageModel(
          messageId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          senderId: userId,
          receiverId: receiverId,
          message: content,
          imageUrl: imageUrl,
          audioUrl: audioUrl,
          isSeen: false,
          isDelivered: false,
          isRead: false,
          timestamp: DateTime.now(),
          replyTo: replyTo,
        );

        emit(
          ChatLoaded(
            chat: currentState.chat.copyWith(
              lastMessage: content.isNotEmpty
                  ? content
                  : (imageUrl != null ? 'صورة' : 'رسالة صوتية'),
              lastMessageTime: DateTime.now(),
              isLastMessageSeen: false,
              isLastMessageDelivered: false,
              lastMessageSenderId: userId,
              unreadCount: currentState.chat.unreadCount + 1,
            ),
            messages: [tempMessage, ...currentState.messages],
          ),
        );

        await _repository.sendMessage(
          chatId,
          content,
          imageUrl: imageUrl,
          audioUrl: audioUrl,
          replyTo: replyTo,
        );
      }
    } catch (e) {
      if (!isClosed && state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(
          ChatLoaded(
            chat: currentState.chat,
            messages: currentState.messages
                .where((m) => !m.messageId.startsWith('temp_'))
                .toList(),
          ),
        );
        emit(ChatError('حدث خطأ أثناء إرسال الرسالة: $e'));
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (state is! ChatLoaded) {
      emit(ChatError('لا يمكن حذف الرسالة في الوقت الحالي'));
      return;
    }

    final currentState = state as ChatLoaded;
    final messages = currentState.messages;
    
    // البحث عن الرسالة المراد حذفها
    final messageToDelete = messages.firstWhere(
      (m) => m.messageId == messageId,
      orElse: () => MessageModel(
        messageId: '',
        senderId: '',
        message: '',
        isSeen: false,
        timestamp: DateTime.now(),
      ),
    );
    
    // إذا لم يتم العثور على الرسالة
    if (messageToDelete.messageId.isEmpty) {
      emit(ChatError('الرسالة غير موجودة'));
      return;
    }
    
    try {
      // تحديث الواجهة أولاً (لتجربة مستخدم أفضل)
      final updatedMessages = messages
          .where((m) => m.messageId != messageId)
          .toList();
      
      emit(ChatLoaded(
        chat: currentState.chat,
        messages: updatedMessages,
      ));

      // حذف الرسالة من Firestore
      await _repository.deleteMessage(chatId, messageId);
      
      // التحقق مما إذا كانت الرسالة المحذوفة هي آخر رسالة في المحادثة
      final isLastMessage = currentState.chat.lastMessageSenderId == messageToDelete.senderId && 
                          (currentState.chat.lastMessage == messageToDelete.message ||
                          (messageToDelete.imageUrl != null && currentState.chat.lastMessage == 'صورة') ||
                          (messageToDelete.audioUrl != null && currentState.chat.lastMessage == 'رسالة صوتية'));
                          
      if (isLastMessage && updatedMessages.isNotEmpty) {
        // تحديث آخر رسالة في المحادثة إلى الرسالة السابقة
        final newLastMessage = updatedMessages.first;
        final String lastMessageText = newLastMessage.message.isNotEmpty 
            ? newLastMessage.message 
            : (newLastMessage.imageUrl != null ? 'صورة' : 'رسالة صوتية');
            
        // تحديث البيانات على واجهة المستخدم
        emit(ChatLoaded(
          chat: currentState.chat.copyWith(
            lastMessage: lastMessageText,
            lastMessageSenderId: newLastMessage.senderId,
            lastMessageTime: newLastMessage.timestamp,
          ),
          messages: updatedMessages,
        ));
        
        // تحديث البيانات في Firestore
        await _repository.updateLastMessage(
          chatId, 
          lastMessageText,
          newLastMessage.senderId,
          newLastMessage.timestamp
        );
      }
    } catch (e) {
      // في حالة الخطأ، إعادة تحميل الرسائل
      if (!isClosed) {
        loadMessages();
        emit(ChatError('حدث خطأ أثناء حذف الرسالة: $e'));
      }
      // إعادة رمي الخطأ ليتم التقاطه في واجهة المستخدم
      throw e;
    }
  }

  void editMessage(String messageId, String newContent) async {
    try {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        await _repository.updateMessage(chatId, messageId, newContent);
        final updatedMessages = currentState.messages.map((m) {
          if (m.messageId == messageId) {
            return m.copyWith(message: newContent, isEdited: true);
          }
          return m;
        }).toList();
        emit(ChatLoaded(
          chat: currentState.chat,
          messages: updatedMessages,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('حدث خطأ أثناء تعديل الرسالة: $e'));
      }
    }
  }

  // Method to explicitly mark messages as read
  Future<void> markMessagesAsRead() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Cannot mark messages as read: User not logged in');
        return;
      }
      
      // Mark messages as read in Firestore
      await _repository.markMessagesAsRead(chatId, userId);
      
      // If we have loaded state, update the unread count in the UI
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        // Update the UI with unread count set to 0
        emit(ChatLoaded(
          chat: currentState.chat.copyWith(unreadCount: 0),
          messages: currentState.messages,
        ));
      }
      
      print('Messages marked as read successfully');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    return super.close();
  }
}