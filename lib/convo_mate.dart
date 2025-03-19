import 'package:flutter/material.dart';
import 'config/routes.dart';

class ConvoMate extends StatelessWidget {
  const ConvoMate({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

