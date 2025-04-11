// lib/data/repositories/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> getConversations(String userId);
  Future<List<UserModel>> searchUsers(String query, List<String> userInterests);
  Future<void> deleteChat(String chatId);
  Future<void> toggleGhostMode(bool isEnabled);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<List<ChatModel>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<ChatModel> chats = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final otherUserId = (data['participants'] as List)
            .firstWhere((id) => id != userId, orElse: () => '');

        if (otherUserId.isEmpty) continue;

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          chats.add(ChatModel(
            chatId: doc.id,
            participants: List<String>.from(data['participants']),
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isLastMessageSeen: data['isLastMessageSeen'] ?? false,
            otherUserName: user.name,
            otherUserImage: user.profileImage,
            unreadCount: data['unreadCount'] ?? 0,
            isOnline: user.isOnline,
            sharedInterests: user.interests,
          ));
        }
      }
      return chats;
    });
  }

  @override
  Future<List<UserModel>> searchUsers(String query, List<String> userInterests) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) =>
    user.uid != _auth.currentUser?.uid &&
        user.interests.any((interest) => userInterests.contains(interest)))
        .toList();

    return users;
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await _firestore.collection('conversations').doc(chatId).delete();
  }

  @override
  Future<void> toggleGhostMode(bool isEnabled) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'isGhostMode': isEnabled,
      });
    }
  }
}