import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/interest/interest_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/sign_up/sign_up_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/home/home_screen.dart'; // شاشة الرئيسية
// import '../presentation/screens/chat/chat_screen.dart'; // شاشة الدردشة
// import '../presentation/screens/search/search_screen.dart'; // شاشة البحث
// import '../presentation/screens/profile/profile_screen.dart'; // شاشة الملف الشخصي
// import '../presentation/screens/settings/settings_screen.dart'; // شاشة الإعدادات
// import '../presentation/screens/notifications/notifications_screen.dart'; // شاشة الإشعارات

final GoRouter router = GoRouter(
  initialLocation: '/', // البدء بشاشة الترحيب
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = user != null;
    final isOnAuthRoute = state.uri.path == '/login' || state.uri.path == '/signup';

    // إذا لم يكن المستخدم مسجل الدخول وحاول الوصول لشاشة محمية، وجهه إلى تسجيل الدخول
    if (!isAuthenticated && !isOnAuthRoute && state.uri.path != '/') {
      return '/login';
    }

    // إذا كان مسجل الدخول وحاول الوصول لتسجيل الدخول أو التسجيل، وجهه إلى الرئيسية
    if (isAuthenticated && isOnAuthRoute) {
      return '/home';
    }

    return null; // لا إعادة توجيه إذا كان كل شيء صحيح
  },
  routes: [
    // 🟢 شاشة الترحيب
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    ),

    // 🟢 شاشة تسجيل الدخول
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    ),

    // 🟢 شاشة إنشاء حساب
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    ),

    // 🟢 شاشة اختيار الاهتمامات
    GoRoute(
      path: '/interest',
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          return const MaterialPage(
            child: Scaffold(body: Center(child: Text('يرجى تسجيل الدخول أولاً'))),
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: InterestSelectionScreen(userId: userId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    ),

    // 🔵 شاشة الرئيسية
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          return const MaterialPage(
            child: Scaffold(body: Center(child: Text('يرجى تسجيل الدخول أولاً'))),
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    ),

    // // 🔴 شاشة الدردشة
    // GoRoute(
    //   path: '/chat/:chatId',
    //   pageBuilder: (context, state) {
    //     final chatId = state.pathParameters['chatId'];
    //     if (chatId == null) {
    //       return const MaterialPage(
    //         child: Scaffold(body: Center(child: Text('معرف المحادثة غير صالح'))),
    //       );
    //     }
    //     return CustomTransitionPage(
    //       key: state.pageKey,
    //       child: ChatScreen(chatId: chatId),
    //       transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
    //         position: Tween<Offset>(
    //           begin: const Offset(0, 1),
    //           end: Offset.zero,
    //         ).animate(animation),
    //         child: child,
    //       ),
    //     );
    //   },
    // ),

//     // 🟢 شاشة البحث
//     GoRoute(
//       path: '/search',
//       pageBuilder: (context, state) => CustomTransitionPage(
//         key: state.pageKey,
//         child: const SearchScreen(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
//           opacity: animation,
//           child: child,
//         ),
//       ),
//     ),
//
//     // 🟢 شاشة الملف الشخصي
//     GoRoute(
//       path: '/profile',
//       pageBuilder: (context, state) {
//         final userId = FirebaseAuth.instance.currentUser?.uid;
//         if (userId == null) {
//           return const MaterialPage(
//             child: Scaffold(body: Center(child: Text('يرجى تسجيل الدخول أولاً'))),
//           );
//         }
//         return CustomTransitionPage(
//           key: state.pageKey,
//           child: const ProfileScreen(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
//               opacity: animation,
//               child: child
//           ),
//         );
//       },
//     ),
//
//     // 🟢 شاشة الإعدادات
//     GoRoute(
//       path: '/settings',
//       pageBuilder: (context, state) => CustomTransitionPage(
//         key: state.pageKey,
//         child: const SettingsScreen(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
//           opacity: animation,
//           child: child,
//         ),
//       ),
//     ),
//
//     // 🟢 شاشة الإشعارات
//     GoRoute(
//       path: '/notifications',
//       pageBuilder: (context, state) => CustomTransitionPage(
//         key: state.pageKey,
//         child: const NotificationsScreen(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
//           opacity: animation,
//           child: child,
//         ),
//       ),
//     ),
//
//     // 🟢 شاشة إنشاء محادثة جديدة
//     GoRoute(
//       path: '/new_chat',
//       pageBuilder: (context, state) => CustomTransitionPage(
//         key: state.pageKey,
//         child: const SearchScreen(), // يمكن إعادة استخدام SearchScreen لاختيار مستخدم
//         transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(0, 1),
//             end: Offset.zero,
//           ).animate(animation),
//           child: child,
//         ),
//       ),
//     ),
   ],
 );