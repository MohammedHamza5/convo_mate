import 'package:flutter/material.dart';
import 'presentation/screens/splash_screen.dart';

class ConvoMate extends StatelessWidget {
  const ConvoMate({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

