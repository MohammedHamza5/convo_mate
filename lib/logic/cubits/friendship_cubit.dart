import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/friend_request_model.dart';
import 'friendship_state.dart';

class FriendshipCubit extends Cubit<FriendshipState> {
  FriendshipCubit() : super(FriendshipInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<FriendRequest>> getFriendRequests(String userId) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FriendRequest.fromFirestore(doc))
        .toList());
  }

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    emit(FriendshipLoading());
    try {
      final requestId = '$fromUserId-$toUserId';
      final requestRef = _firestore.collection('friend_requests').doc(requestId);
      final existingRequest = await requestRef.get();
      if (existingRequest.exists) {
        emit(FriendshipError('تم إرسال طلب الصداقة مسبقًا'));
        return;
      }

      await requestRef.set(FriendRequest(
        id: requestId,
        from: fromUserId,
        to: toUserId,
        status: 'pending',
        createdAt: DateTime.now(),
      ).toJson());
      emit(FriendshipRequestSent());
    } catch (e) {
      emit(FriendshipError('فشل إرسال طلب الصداقة: $e'));
    }
  }

  Future<void> acceptFriendRequest(String fromUserId, String toUserId) async {
    emit(FriendshipLoading());
    try {
      final requestId = '$fromUserId-$toUserId';
      final requestRef = _firestore.collection('friend_requests').doc(requestId);
      await _firestore.runTransaction((transaction) async {
        transaction.update(requestRef, {'status': 'accepted'});

        final fromUserRef = _firestore.collection('users').doc(fromUserId);
        final toUserRef = _firestore.collection('users').doc(toUserId);

        transaction.update(fromUserRef, {
          'friends': FieldValue.arrayUnion([toUserId]),
        });
        transaction.update(toUserRef, {
          'friends': FieldValue.arrayUnion([fromUserId]),
        });
      });
      emit(FriendshipRequestAccepted());
    } catch (e) {
      emit(FriendshipError('فشل قبول طلب الصداقة: $e'));
    }
  }

  Future<void> declineFriendRequest(String fromUserId, String toUserId) async {
    emit(FriendshipLoading());
    try {
      final requestId = '$fromUserId-$toUserId';
      final requestRef = _firestore.collection('friend_requests').doc(requestId);
      await requestRef.delete();
      emit(FriendshipRequestDeclined());
    } catch (e) {
      emit(FriendshipError('فشل رفض طلب الصداقة: $e'));
    }
  }

  Future<void> removeFriend(String fromUserId, String toUserId) async {
    emit(FriendshipLoading());
    try {
      await _firestore.runTransaction((transaction) async {
        final fromUserRef = _firestore.collection('users').doc(fromUserId);
        final toUserRef = _firestore.collection('users').doc(toUserId);

        transaction.update(fromUserRef, {
          'friends': FieldValue.arrayRemove([toUserId]),
        });
        transaction.update(toUserRef, {
          'friends': FieldValue.arrayRemove([fromUserId]),
        });
      });
      emit(FriendshipRemoved());
    } catch (e) {
      emit(FriendshipError('فشل إلغاء الصداقة: $e'));
    }
  }
}