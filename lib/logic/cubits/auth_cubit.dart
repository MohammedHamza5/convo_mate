import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthCubit() : super(AuthInitial());

  Future<bool> _hasSelectedInterests(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;
    final data = userDoc.data();
    return data != null &&
        data.containsKey('interests') &&
        (data['interests'] as List).isNotEmpty;
  }

  Future<void> loginWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final hasInterests = await _hasSelectedInterests(userCredential.user!.uid);
      emit(AuthSuccess(hasSelectedInterests: hasInterests));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> registerWithEmail(
      String email, String password, String username) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await userCredential.user!.updateDisplayName(username);

      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        name: username,
        email: email,
        profileImage: '',
        interests: [],
        friends: [],
        isOnline: true,
        lastSeen: DateTime.now(),
        maritalStatus: null,
        bio: null,
        birthDate: null,
        city: null,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());

      emit(AuthSuccess(hasSelectedInterests: false));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthFailure("لم يكتمل تسجيل الدخول."));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userId = userCredential.user!.uid;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        UserModel userModel = UserModel(
          uid: userId,
          name: googleUser.displayName ?? 'مستخدم',
          email: googleUser.email,
          profileImage: googleUser.photoUrl,
          interests: [],
          friends: [],
          isOnline: true,
          lastSeen: DateTime.now(),
          maritalStatus: null,
          bio: null,
          birthDate: null,
          city: null,
        );
        await _firestore.collection('users').doc(userId).set(userModel.toJson());
        emit(AuthSuccess(hasSelectedInterests: false));
      } else {
        final hasInterests = await _hasSelectedInterests(userId);
        emit(AuthSuccess(hasSelectedInterests: hasInterests));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    emit(AuthInitial());
  }
}