import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repositories.dart';
import 'home_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class HomeCubit extends Cubit<HomeState> {
  final ChatRepository _chatRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<List<ChatModel>>? _conversationsSubscription;

  HomeCubit(this._chatRepository) : super(HomeInitial());

  void loadConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      emit(HomeError('لم يتم تسجيل الدخول'));
      return;
    }
    try {
      _conversationsSubscription?.cancel(); // إلغاء الاشتراك السابق
      final stream = _chatRepository.getConversations(userId);
      _conversationsSubscription = stream.listen(
            (chats) {
          if (!isClosed) {
            emit(HomeLoaded(chats: chats));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(HomeError('حدث خطأ أثناء جلب المحادثات: $error'));
            print('Error loading conversations: $error');
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(HomeError('حدث خطأ: $e'));
      }
    }
  }

  void searchUsers(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      emit(HomeError('لم يتم تسجيل الدخول'));
      return;
    }

    if (query.isEmpty) {
      emit(HomeInitial());
      return;
    }

    emit(HomeSearching());
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userInterests = List<String>.from(userDoc.data()?['interests'] ?? []);
      final users = await _chatRepository.searchUsers(query, userInterests);
      emit(HomeSearchResult(users));
    } catch (e) {
      emit(HomeError('حدث خطأ أثناء البحث: $e'));
    }
  }

  void clearSearch() {
    emit(HomeInitial());
  }

  void deleteChat(String chatId) async {
    try {
      await _chatRepository.deleteChat(chatId);
      loadConversations(); // إعادة تحميل المحادثات بعد الحذف
    } catch (e) {
      emit(HomeError('حدث خطأ أثناء حذف المحادثة: $e'));
    }
  }

  void toggleGhostMode(bool isEnabled) async {
    try {
      await _chatRepository.toggleGhostMode(isEnabled);
      emit(HomeGhostModeToggled(isEnabled));
    } catch (e) {
      emit(HomeError('حدث خطأ أثناء تفعيل وضع التخفي: $e'));
    }
  }

  void logout() async {
    try {
      // قم بتسجيل الخروج مباشرة
      await _auth.signOut();
      emit(HomeLoggedOut());
    } catch (e) {
      emit(HomeError('حدث خطأ أثناء تسجيل الخروج: $e'));
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = null;
    return super.close();
  }
}