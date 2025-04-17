import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../logic/cubits/auth_cubit.dart';

class GoogleSignInButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const GoogleSignInButton({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: () {
        // Call the AuthCubit to perform Google Sign-In
        BlocProvider.of<AuthCubit>(context).signInWithGoogle();
      },
      icon: Image.asset(
        'assets/icons/google_logo.png',
        height: 24.h,
        width: 24.w,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to an icon if the image is not found
          return Icon(
            Icons.g_mobiledata,
            size: 24.sp,
            color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
          );
        },
      ),
      label: Text(
        localizations.signInWithGoogle,
        style: GoogleFonts.cairo(
          fontSize: fontSize ?? 16.sp,
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? (isDarkMode ? Colors.grey[800] : Colors.white),
        foregroundColor: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        elevation: 2,
      ),
    );
  }
}