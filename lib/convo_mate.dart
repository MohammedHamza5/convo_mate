import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'core/theme.dart';

class ConvoMate extends StatelessWidget {
  const ConvoMate({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

