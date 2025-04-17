import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart' as AppRouter;
import 'core/theme.dart';
import 'firebase_options.dart';
import 'logic/providers/presence_provider.dart';
import 'logic/providers/locale_provider.dart';
import 'data/repositories/user_presence_repository.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Create the repository first
  final _presenceRepository = UserPresenceRepository();
  // Then pass it to the provider
  late final PresenceProvider _presenceProvider;
  // Create locale provider
  final _localeProvider = LocaleProvider();
  final _router = AppRouter.router;

  @override
  void initState() {
    super.initState();
    // Initialize presence provider with repository
    _presenceProvider = PresenceProvider(repository: _presenceRepository);
    // بدء مراقبة حالة دورة حياة التطبيق
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // إيقاف مراقبة حالة دورة حياة التطبيق
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // تحديث حالة نشاط التطبيق بناءً على دورة حياة التطبيق
    print('App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق في المقدمة ونشط
        print('App is resumed - setting user as online');
        _presenceProvider.setOnlineOnAppOpen();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // التطبيق في الخلفية أو مغلق
        print('App is inactive/paused/detached - setting user as offline');
        _presenceProvider.setOfflineOnAppClose();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => _presenceProvider),
            ChangeNotifierProvider(create: (_) => _localeProvider),
          ],
          child: Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return MaterialApp.router(
                title: 'Convo Mate',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
                routerConfig: _router,
                locale: localeProvider.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            }
          ),
        );
      },
    );
  }
}
