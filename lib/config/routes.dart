import 'package:convo_mate/presentation/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/login/login_screen.dart';


final GoRouter router = GoRouter(
  routes: [

    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    // 🟢 شاشة تسجيل الدخول
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    // // 🟡 شاشة إنشاء حساب
    // GoRoute(
    //   path: '/register',
    //   builder: (context, state) => RegisterScreen(),
    // ),
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