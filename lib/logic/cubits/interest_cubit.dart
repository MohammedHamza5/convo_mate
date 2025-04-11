import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/interest_model.dart';
import 'interest_state.dart';

class InterestCubit extends Cubit<InterestState> {
  InterestCubit() : super(InterestInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> selectedInterests = [];
  List<InterestModel> allInterests = [];

  void loadInterests() async {
    emit(InterestLoading());
    try {
      QuerySnapshot snapshot = await _firestore.collection('interests').get();
      if (snapshot.docs.isEmpty) {
        await addInterestsToFirestore(); // إضافة الاهتمامات إذا لم تكن موجودة
        snapshot = await _firestore.collection('interests').get(); // إعادة جلب البيانات
      }
      allInterests = snapshot.docs.map((doc) {
        return InterestModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      emit(InterestLoaded(allInterests, selectedInterests));
    } catch (e) {
      emit(InterestError('فشل تحميل الاهتمامات: $e'));
    }
  }

  void toggleInterest(String interestId) {
    if (selectedInterests.contains(interestId)) {
      selectedInterests.remove(interestId);
    } else if (selectedInterests.length < 5) {
      selectedInterests.add(interestId);
    }
    emit(InterestLoaded(allInterests, List.from(selectedInterests)));
  }

  Future<void> saveInterests(String userId) async {
    if (selectedInterests.length < 3) {
      emit(InterestError('يرجى اختيار 3 اهتمامات على الأقل'));
      return;
    }
    emit(InterestSaving());
    try {
      await _firestore.collection('users').doc(userId).update({
        'interests': selectedInterests,
      });
      emit(InterestSaved());
    } catch (e) {
      emit(InterestError('فشل حفظ الاهتمامات: $e'));
    }
  }

  Future<void> addInterestsToFirestore() async {
    final collectionRef = _firestore.collection('interests');
    // التحقق مما إذا كانت الاهتمامات مضافة مسبقًا
    QuerySnapshot snapshot = await collectionRef.get();
    if (snapshot.docs.isNotEmpty) {
      print("⚠ الاهتمامات موجودة بالفعل في Firestore.");
      return;
    }

    List<InterestModel> interests = [
      InterestModel(id: '1', name: 'رياضة', icon: 'assets/icons/sports-basketball-svgrepo-com.svg'),
      InterestModel(id: '2', name: 'تقنية', icon: 'assets/icons/chat-computer-support-svgrepo-com.svg'),
      InterestModel(id: '3', name: 'أفلام', icon: 'assets/icons/movies-svgrepo-com.svg'),
      InterestModel(id: '4', name: 'كتب', icon: 'assets/icons/books-book-svgrepo-com.svg'),
      InterestModel(id: '5', name: 'موسيقى', icon: 'assets/icons/music-notes-svgrepo-com.svg'),
      InterestModel(id: '6', name: 'سفر', icon: 'assets/icons/travel-svgrepo-com.svg'),
      InterestModel(id: '7', name: 'ألعاب', icon: 'assets/icons/gaming-pad-svgrepo-com.svg'),
      InterestModel(id: '8', name: 'طعام', icon: 'assets/icons/food-and-drink-svgrepo-com.svg'),
    ];

    try {
      for (var interest in interests) {
        await collectionRef.doc(interest.id).set(interest.toMap(), SetOptions(merge: true));
      }
      print("✅ الاهتمامات تمت إضافتها إلى Firestore بنجاح!");
    } catch (e) {
      print("حدث خطأ أثناء إضافة الاهتمامات: $e");
      throw e; // للسماح بمعالجة الخطأ في loadInterests
    }
  }
}