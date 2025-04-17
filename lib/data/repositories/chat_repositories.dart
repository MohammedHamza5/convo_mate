import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ChatModel> getChatDetails(String chatId) async {
    final doc = await _firestore.collection('conversations').doc(chatId).get();
    if (!doc.exists) {
      throw Exception('Chat not found');
    }
    return ChatModel.fromJson(doc.data()!, doc.id);
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  @override
  Future<void> sendMessage(
      String chatId,
      String content, {
        String? imageUrl,
        String? audioUrl,
        int? audioDuration,
        String? replyTo,
      }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    // احصل على معرف المستلم من المشاركين في المحادثة
    final chatDoc = await _firestore.collection('conversations').doc(chatId).get();
    final chatData = chatDoc.data()!;
    final participants = List<String>.from(chatData['participants'] ?? []);
    final receiverId = participants.firstWhere((id) => id != userId, orElse: () => '');
    
    if (receiverId.isEmpty) {
      throw Exception('لم يتم العثور على المستلم');
    }

    final messageId = _firestore.collection('conversations').doc().id;
    final message = MessageModel(
      messageId: messageId,
      senderId: userId,
      receiverId: receiverId,  // تعيين معرف المستلم بشكل صريح
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

    await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toJson());

    // تحديث آخر رسالة في المحادثة
    final lastMessageText = content.isNotEmpty
        ? content
        : (imageUrl != null ? 'صورة' : 'رسالة صوتية');
    
    // تحديث آخر رسالة ومعلومات المحادثة
    final conversationRef = _firestore.collection('conversations').doc(chatId);
    
    // تحديث معلومات المحادثة الأساسية
    await conversationRef.update({
      'lastMessage': lastMessageText,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'isLastMessageSeen': false,
      'isLastMessageDelivered': false,
      'lastMessageSenderId': userId,
      'otherUserId': receiverId,
    });
    
    // زيادة عدد الرسائل غير المقروءة فقط للمستلم (المستخدم الآخر)
    // الرسائل التي يرسلها المستخدم الحالي لا تزيد عدد الرسائل غير المقروءة له
    
    // نحن بحاجة إلى التحقق من آخر مستخدم فتح المحادثة لنقرر هل نزيد العداد أم لا
    final lastOpenedByField = 'lastOpenedBy_$receiverId';
    final unreadCountField = 'unreadCount_$receiverId';
    
    // تحديث عداد الرسائل غير المقروءة للمستلم
    await conversationRef.update({
      unreadCountField: FieldValue.increment(1),
    });
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Future<void> updateLastMessage(
      String chatId, 
      String lastMessage, 
      String lastMessageSenderId, 
      DateTime lastMessageTime) async {
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .update({
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    });
  }

  @override
  Future<void> updateMessage(
      String chatId, String messageId, String newContent) async {
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': newContent,
      'isEdited': true,
    });
  }

  @override
  Future<void> markMessagesAsDelivered(String chatId, String userId) async {
    try {
      // تحديث الرسائل المرسلة إلى المستخدم الحالي والتي لم يتم تسليمها بعد
      final messages = await _firestore
          .collection('conversations')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isDelivered', isEqualTo: false)
          .get();

      if (messages.docs.isEmpty) {
        // لا توجد رسائل للتحديث
        return;
      }

      final batch = _firestore.batch();
      int messageCount = 0;
      
      for (var doc in messages.docs) {
        // التحقق من أن المستند يحتوي على البيانات المطلوبة
        if (doc.exists) {
          batch.update(doc.reference, {
            'isDelivered': true,
            // تأكد من تحديث حقول أخرى مرتبطة إذا لزم الأمر
            'deliveredAt': Timestamp.now(),
          });
          messageCount++;
        }
      }

      // تحديث حالة آخر رسالة في المحادثة إذا كانت مرسلة إلى المستخدم الحالي
      final chatDoc = await _firestore.collection('conversations').doc(chatId).get();
      if (!chatDoc.exists) {
        // المحادثة غير موجودة
        return;
      }
      
      final chatData = chatDoc.data()!;
      final lastMessageSenderId = chatData['lastMessageSenderId'] as String? ?? '';
      
      if (lastMessageSenderId != userId && chatData['isLastMessageDelivered'] == false) {
        batch.update(_firestore.collection('conversations').doc(chatId), {
          'isLastMessageDelivered': true,
          'lastMessageDeliveredAt': Timestamp.now(),
        });
      }
      
      // تنفيذ عملية التحديث الجماعية فقط إذا كان هناك تحديثات
      if (messageCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // يمكنك إعادة رمي الاستثناء هنا إذا لزم الأمر
      // throw e;
    }
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // تحديث الرسائل المرسلة إلى المستخدم الحالي والتي لم يتم قراءتها بعد
      final messages = await _firestore
          .collection('conversations')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messages.docs.isEmpty) {
        // لا توجد رسائل للتحديث
        return;
      }

      final batch = _firestore.batch();
      int messageCount = 0;
      
      for (var doc in messages.docs) {
        // التحقق من أن المستند يحتوي على البيانات المطلوبة
        if (doc.exists) {
          batch.update(doc.reference, {
            'isRead': true,
            'isSeen': true,  // للتوافق مع الحقول القديمة
            'readAt': Timestamp.now(),
          });
          messageCount++;
        }
      }

      // تحديث حالة آخر رسالة في المحادثة إذا كانت مرسلة إلى المستخدم الحالي
      final chatDoc = await _firestore.collection('conversations').doc(chatId).get();
      if (!chatDoc.exists) {
        // المحادثة غير موجودة
        return;
      }
      
      final chatData = chatDoc.data()!;
      final lastMessageSenderId = chatData['lastMessageSenderId'] as String? ?? '';
      
      if (lastMessageSenderId != userId && chatData['isLastMessageSeen'] == false) {
        // تحديث حالة المحادثة لتعكس أن الرسالة الأخيرة تمت قراءتها
        final updateData = {
          'isLastMessageSeen': true,
          'lastMessageReadAt': Timestamp.now(),
        };
        
        // إعادة تعيين عداد الرسائل غير المقروءة للمستخدم الحالي
        final unreadCountField = 'unreadCount_$userId';
        updateData[unreadCountField] = 0;
        
        // تحديث المستند
        batch.update(_firestore.collection('conversations').doc(chatId), updateData);
        
        // تحديث حقل "آخر من فتح المحادثة"
        batch.update(_firestore.collection('conversations').doc(chatId), {
          'lastOpenedBy_$userId': Timestamp.now(),
        });
      }
      
      // تنفيذ عملية التحديث الجماعية فقط إذا كان هناك تحديثات
      if (messageCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // يمكنك إعادة رمي الاستثناء هنا إذا لزم الأمر
      // throw e;
    }
  }

  @override
  Stream<List<ChatModel>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ChatModel.fromJson(doc.data(), doc.id)).toList());
  }

  @override
  Future<List<UserModel>> searchUsers(String query, List<String> userInterests) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) =>
        userInterests.any((interest) => user.interests.contains(interest)))
        .toList();

    return users;
  }

  @override
  Future<void> deleteChat(String chatId) async {
    // حذف جميع الرسائل في المحادثة
    final messages = await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    // حذف مستند المحادثة
    await _firestore.collection('conversations').doc(chatId).delete();
  }

  @override
  Future<void> toggleGhostMode(bool isEnabled) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // Update Firestore document
      await _firestore.collection('users').doc(userId).update({
        'isGhostMode': isEnabled,
      });
      
      // Check if user is online and update the presence indicator
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isOnline = userDoc.data()?['isOnline'] ?? false;
    } catch (e) {
      throw Exception('فشل في تحديث وضع التخفي: $e');
    }
  }
}

abstract class ChatRepository {
  Future<ChatModel> getChatDetails(String chatId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(
      String chatId,
      String content, {
        String? imageUrl,
        String? audioUrl,
        int? audioDuration,
        String? replyTo,
      });
  Future<void> deleteMessage(String chatId, String messageId);
  Future<void> updateMessage(String chatId, String messageId, String newContent);
  Future<void> updateLastMessage(String chatId, String lastMessage, String lastMessageSenderId, DateTime lastMessageTime);
  Future<void> markMessagesAsDelivered(String chatId, String userId);
  Future<void> markMessagesAsRead(String chatId, String userId);
  Stream<List<ChatModel>> getConversations(String userId);
  Future<List<UserModel>> searchUsers(String query, List<String> userInterests);
  Future<void> deleteChat(String chatId);
  Future<void> toggleGhostMode(bool isEnabled);
}