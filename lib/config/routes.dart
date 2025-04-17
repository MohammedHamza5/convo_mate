import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:convo_mate/presentation/screens/main/main_screen.dart';
import 'package:convo_mate/presentation/screens/chat/chat_screen.dart';
import 'package:convo_mate/presentation/screens/edit_profile/edit_profile_screen.dart';
import 'package:convo_mate/presentation/screens/friend_requests/friend_requests_screen.dart';
import 'package:convo_mate/presentation/screens/interest/interest_screen.dart';
import 'package:convo_mate/presentation/screens/login/login_screen.dart';
import 'package:convo_mate/presentation/screens/profile/profile_screen.dart';
import 'package:convo_mate/presentation/screens/search/search_screen.dart';
import 'package:convo_mate/presentation/screens/settings/settings_screen.dart';
import 'package:convo_mate/presentation/screens/sign_up/sign_up_screen.dart';
import 'package:convo_mate/presentation/screens/splash/splash_screen.dart';
import 'package:convo_mate/presentation/screens/home/home_screen.dart';

// Reusable error screen
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
      ),
    );
  }
}


// Router configuration
final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true, // إضافة سجل للتنقل
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = user != null;
    final isOnAuthRoute = state.uri.path == '/login' || state.uri.path == '/signup';
    final isOnSplash = state.uri.path == '/';
    Future<bool> hasSelectedInterests(String userId) async {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      final data = userDoc.data();
      return data != null && data.containsKey('interests') && (data['interests'] as List).isNotEmpty;
    }
    if (!isAuthenticated && !isOnAuthRoute && !isOnSplash) {
      return '/login';
    }
    if (isAuthenticated) {
      final hasInterests = await hasSelectedInterests(user.uid);
      if (isOnAuthRoute) {
        return hasInterests ? '/home' : '/interest';
      }
      if (!hasInterests && state.uri.path != '/interest') {
        return '/interest';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/interest',
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        return CustomTransitionPage(
          key: state.pageKey,
          child: userId != null
              ? InterestSelectionScreen(userId: userId)
              : const ErrorScreen(message: 'يرجى تسجيل الدخول أولاً'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/friend_requests',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FriendRequestsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SearchScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return CustomTransitionPage(
              key: state.pageKey,
              child: userId != null
                  ? ProfileScreen(userId: userId)
                  : const ErrorScreen(message: 'يرجى تسجيل الدخول أولاً'),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/chat/:chatId',
      pageBuilder: (context, state) {
        final chatId = state.pathParameters['chatId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: chatId != null
              ? ChatScreen(chatId: chatId)
              : const ErrorScreen(message: 'معرف المحادثة غير صالح'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        return CustomTransitionPage(
          key: state.pageKey,
          child: userId != null
              ? const SettingsScreen()
              : const ErrorScreen(message: 'يرجى تسجيل الدخول أولاً'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
    GoRoute(
      path: '/profile/:userId',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: userId != null
              ? ProfileScreen(userId: userId)
              : const ErrorScreen(message: 'معرف المستخدم غير صالح'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
    GoRoute(
      path: '/edit_profile',
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        return CustomTransitionPage(
          key: state.pageKey,
          child: userId != null
              ? const EditProfileScreen()
              : const ErrorScreen(message: 'يرجى تسجيل الدخول أولاً'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
  ],
);