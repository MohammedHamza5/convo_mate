import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/routes.dart';
import 'logic/providers/locale_provider.dart';

class ConvoMate extends StatelessWidget {
  const ConvoMate({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return MaterialApp.router(
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('ar', ''),
                Locale('en', ''),
                Locale('de', ''),
              ],
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                primarySwatch: Colors.blue,
                textTheme: GoogleFonts.cairoTextTheme(),
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.white,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.blueGrey,
                textTheme: GoogleFonts.cairoTextTheme().apply(bodyColor: Colors.white),
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.grey[900],
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              themeMode: ThemeMode.system,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, widget) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: widget!,
                );
              },
            );
          },
        );
      },
    );
  }
}
