import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../logic/cubits/interest_cubit.dart';
import '../../../logic/cubits/interest_state.dart';

class InterestSelectionScreen extends StatelessWidget {
  final String userId;

  const InterestSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = isDarkMode ? Colors.blueGrey.shade700 : Colors.blue.shade400;

    return BlocProvider(
      create: (context) => InterestCubit()..loadInterests(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.selectInterests,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: textColor,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: backgroundColor,
          elevation: 0,
          foregroundColor: textColor,
        ),
        body: BlocConsumer<InterestCubit, InterestState>(
          listener: (context, state) {
            if (state is InterestSaved) {
              context.go('/home');
            } else if (state is InterestError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.errorMessage(state.error),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is InterestLoading) {
              return Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 4.w));
            } else if (state is InterestLoaded) {
              return Column(
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.chooseInterests,
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 40.w,
                                height: 40.h,
                                child: CircularProgressIndicator(
                                  value: state.selectedInterests.length / 5,
                                  strokeWidth: 4.w,
                                  color: accentColor,
                                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                ),
                              ),
                              Text(
                                '${state.selectedInterests.length}/5',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: state.interests.length,
                      itemBuilder: (context, index) {
                        final interest = state.interests[index];
                        final isSelected = state.selectedInterests.contains(interest.name);
                        return FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          child: GestureDetector(
                            onTap: () => context.read<InterestCubit>().toggleInterest(interest.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [accentColor, accentColor.withOpacity(0.7)]
                                      : isDarkMode
                                      ? [Colors.grey[800]!, Colors.grey[850]!]
                                      : [Colors.grey[200]!, Colors.grey[300]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                                border: Border.all(
                                  color: isSelected ? accentColor.withOpacity(0.5) : Colors.transparent,
                                  width: 2.w,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  interest.icon != null
                                      ? SvgPicture.asset(
                                    interest.icon!,
                                    height: 48.h,
                                    width: 48.w,
                                    color: isSelected
                                        ? Colors.white
                                        : isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black87,
                                  )
                                      : Icon(
                                    Icons.interests,
                                    size: 48.sp,
                                    color: isSelected
                                        ? Colors.white
                                        : isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black87,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    interest.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: isSelected ? 18.sp : 16.sp,
                                      color: isSelected
                                          ? Colors.white
                                          : isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: state.selectedInterests.length >= 3
                              ? () => context.read<InterestCubit>().saveInterests(userId)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.selectedInterests.length >= 3
                                ? accentColor
                                : isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 56.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: state.selectedInterests.length >= 3 ? 8 : 2,
                            shadowColor: state.selectedInterests.length >= 3
                                ? accentColor.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                          child: state is InterestSaving
                              ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          )
                              : Text(
                            localizations.nextButton,
                            style: GoogleFonts.cairo(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is InterestError) {
              return Center(
                child: Text(
                  localizations.errorMessage(state.error),
                  style: GoogleFonts.cairo(fontSize: 16.sp, color: Colors.red),
                ),
              );
            }
            return Center(
              child: Text(
                localizations.noData,
                style: GoogleFonts.cairo(fontSize: 16.sp, color: isDarkMode ? Colors.grey[400] : Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
}