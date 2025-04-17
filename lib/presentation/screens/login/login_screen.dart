import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../logic/cubits/auth_cubit.dart';
import '../../../logic/cubits/auth_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_form.dart';
import '../../widgets/google_sign_in_button.dart';
import 'widgets/do_not_have_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = isDarkMode ? Colors.blueGrey.shade700 : Colors.blue.shade400;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocProvider(
        create: (context) => AuthCubit(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go(state.hasSelectedInterests ? '/home' : '/interest');
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error, style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Icon(
                        Icons.lock_outline,
                        size: 80.sp,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        localizations.welcomeBack,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SlideInLeft(
                            delay: const Duration(milliseconds: 500),
                            child: CustomTextField(
                              controller: emailController,
                              hintText: localizations.emailAddress,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icon(Icons.email_outlined, color: textColor.withOpacity(0.6), size: 20.sp),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseEnterYourEmail; // Translated
                                }
                                return null;
                              },
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              textColor: textColor,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          SlideInRight(
                            delay: const Duration(milliseconds: 600),
                            child: CustomTextField(
                              controller: passwordController,
                              hintText: localizations.password,
                              obscureText: _obscurePassword,
                              prefixIcon: Icon(Icons.lock_outline, color: textColor.withOpacity(0.6), size: 20.sp),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseEnterYourPassword; // Translated
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: textColor.withOpacity(0.6),
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              textColor: textColor,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25.h),
                    state is AuthLoading
                        ? CircularProgressIndicator(color: accentColor, strokeWidth: 4.w)
                        : BounceInUp(
                      delay: const Duration(milliseconds: 700),
                      child: CustomButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthCubit>().loginWithEmail(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          }
                        },
                        text: localizations.loginButton,
                        backgroundColor: accentColor,
                        textColor: Colors.white,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 50.h),
                    if (state is! AuthLoading)
                      GoogleSignInButton(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        textColor: textColor,
                        fontSize: 16.sp,
                      ),
                    SizedBox(height: 50.h),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: DoNotHaveAccountText(
                        textColor: textColor,
                        accentColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}