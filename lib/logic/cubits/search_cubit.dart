import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) {
      emit(SearchSuccess([]));
      return;
    }

    emit(SearchLoading());
    try {
      // البحث بناءً على الاسم
      QuerySnapshot nameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      List<UserModel> users = nameSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUserId) // استبعاد المستخدم الحالي
          .toList();

      // البحث بناءً على الاهتمامات
      QuerySnapshot interestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('interests', arrayContains: query)
          .get();

      users.addAll(interestsSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUserId));

      // إزالة التكرارات
      users = users.toSet().toList();

      emit(SearchSuccess(users));
    } catch (e) {
      emit(SearchFailure('حدث خطأ أثناء البحث: $e'));
    }
  }
}