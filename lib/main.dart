import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/routes.dart' as AppRouter;
import 'core/theme.dart';
import 'firebase_options.dart';
import 'logic/providers/presence_provider.dart';
import 'logic/providers/locale_provider.dart';
import 'data/repositories/user_presence_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _presenceRepository = UserPresenceRepository();
  late final PresenceProvider _presenceProvider;
  final _localeProvider = LocaleProvider();
  final _router = AppRouter.router;

  @override
  void initState() {
    super.initState();
    _presenceProvider = PresenceProvider(repository: _presenceRepository);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presenceProvider.setOnlineOnAppOpen();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
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
                builder: (context, widget) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: widget!,
                ),
              );
            },
          ),
        );
      },
    );
  }
}