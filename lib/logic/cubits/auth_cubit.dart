import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthCubit() : super(AuthInitial());

  Future<void> loginWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> registerWithEmail(
    String email,
    String password,
    String username,
  ) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(username);
      emit(AuthSuccess());
      // إنشاء كائن UserModel
      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        name: username,
        email: email,
        // phone: phone,
        profileImage: '', // صورة افتراضية
        interests: [], // قائمة فارغة في البداية
        isOnline: false, // غير متصل افتراضيًا
        lastSeen: DateTime.now(), // الوقت الحالي
      );

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In cancelled by user");
        emit(AuthFailure("لم يكتمل تسجيل الدخول."));
        return;
      }

      print("Google User: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      print("Google Sign-In successful");
      emit(AuthSuccess());
    } catch (e) {
      print("Google Sign-In error: $e");
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    emit(AuthInitial());
  }
}
