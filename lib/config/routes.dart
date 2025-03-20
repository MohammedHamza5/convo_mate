import 'package:go_router/go_router.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/sign_up/sign_up_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    // 🟢 شاشة تسجيل الدخول
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    // // 🟡 شاشة إنشاء حساب
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignUpScreen(),
    ),
    // // 🔵 الصفحة الرئيسية
    // GoRoute(
    //   path: '/home',
    //   builder: (context, state) => HomeScreen(),
    // ),
    // // 🔴 شاشة الدردشة مع تمرير userId
    // GoRoute(
    //   path: '/chat/:userId',
    //   builder: (context, state) {
    //     final userId = state.pathParameters['userId'];
    //     return ChatScreen(userId: userId!);
    //   },
    // ),
  ],
);
