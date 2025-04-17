import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DoNotHaveAccountText extends StatelessWidget {
  final Color? textColor;
  final Color? accentColor;

  const DoNotHaveAccountText({super.key, this.textColor, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final linkColor = accentColor ?? (isDarkMode ? Colors.blueGrey.shade400 : Colors.blue.shade400);
    return RichText(
      text: TextSpan(
        text: localizations.doNotHaveAccount,
        style: GoogleFonts.cairo(
          fontSize: 14.sp,
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
        ),
        children: [
          TextSpan(
            text: localizations.signUpLink,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: linkColor,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.go('/signup');
              },
          ),
        ],
      ),
    );
  }
}