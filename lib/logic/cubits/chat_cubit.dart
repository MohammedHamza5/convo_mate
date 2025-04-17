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
      await _repository.markMessagesAsDelivered(chatId, userId);
      await _repository.markMessagesAsRead(chatId, userId);

      _messagesSubscription?.cancel();
      final messagesStream = _repository.getMessages(chatId);
      _messagesSubscription = messagesStream.listen(
            (messages) async {
          if (!isClosed) {
            final hasNewMessages = messages.any((msg) =>
            msg.receiverId == userId && (!msg.isDelivered || !msg.isRead));
            if (hasNewMessages) {
              await _repository.markMessagesAsDelivered(chatId, userId);
              await _repository.markMessagesAsRead(chatId, userId);
            }
            emit(ChatLoaded(messages: messages, chat: chat!));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(ChatError('حدث خطأ أثناء جلب الرسائل: $error'));
          }
        },
      );

      Timer.periodic(Duration(seconds: 5), (timer) async {
        if (isClosed) {
          timer.cancel();
          return;
        }
        if (state is ChatLoaded) {
          await _repository.markMessagesAsDelivered(chatId, userId);
          await _repository.markMessagesAsRead(chatId, userId);
        }
      });
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('حدث خطأ: $e'));
      }
    }
  }

  void sendMessage(String content, {
    String? imageUrl,
    String? audioUrl,
    int? audioDuration,
    String? replyTo,
  }) async {
    try {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        
        if (userId.isEmpty) {
          emit(ChatError('لم يتم تسجيل الدخول'));
          return;
        }

        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempMessage = MessageModel(
          messageId: tempId,
          senderId: userId,
          receiverId: currentState.chat.otherUserId,
          message: content,
          imageUrl: imageUrl,
          audioUrl: audioUrl,
          audioDuration: audioDuration,
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
          audioDuration: audioDuration,
          replyTo: replyTo,
        );
      }
    } catch (e) {
      if (!isClosed && state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(
          ChatLoaded(
            chat: currentState.chat,
            messages: currentState.messages.where((m) => !m.messageId.startsWith('temp_')).toList(),
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

    if (messageToDelete.messageId.isEmpty) {
      emit(ChatError('الرسالة غير موجودة'));
      return;
    }

    try {
      final updatedMessages = messages.where((m) => m.messageId != messageId).toList();
      emit(ChatLoaded(
        chat: currentState.chat,
        messages: updatedMessages,
      ));

      await _repository.deleteMessage(chatId, messageId);

      final isLastMessage = currentState.chat.lastMessageSenderId == messageToDelete.senderId &&
          (currentState.chat.lastMessage == messageToDelete.message ||
              (messageToDelete.imageUrl != null && currentState.chat.lastMessage == 'صورة') ||
              (messageToDelete.audioUrl != null && currentState.chat.lastMessage == 'رسالة صوتية'));

      if (isLastMessage && updatedMessages.isNotEmpty) {
        final newLastMessage = updatedMessages.first;
        final String lastMessageText = newLastMessage.message.isNotEmpty
            ? newLastMessage.message
            : (newLastMessage.imageUrl != null ? 'صورة' : 'رسالة صوتية');
        emit(ChatLoaded(
          chat: currentState.chat.copyWith(
            lastMessage: lastMessageText,
            lastMessageSenderId: newLastMessage.senderId,
            lastMessageTime: newLastMessage.timestamp,
          ),
          messages: updatedMessages,
        ));
        await _repository.updateLastMessage(
          chatId,
          lastMessageText,
          newLastMessage.senderId,
          newLastMessage.timestamp,
        );
      }
    } catch (e) {
      if (!isClosed) {
        loadMessages();
        emit(ChatError('حدث خطأ أثناء حذف الرسالة: $e'));
      }
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

  Future<void> markMessagesAsRead() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return;
      }
      await _repository.markMessagesAsRead(chatId, userId);
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(ChatLoaded(
          chat: currentState.chat.copyWith(unreadCount: 0),
          messages: currentState.messages,
        ));
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    return super.close();
  }
}