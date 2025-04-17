import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../logic/cubits/auth_cubit.dart';
import '../../../logic/cubits/auth_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/custom_text_form.dart';
import '../sign_up/widgets/already_have_account_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
              context.go('/interest');
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeInDown(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          localizations.signUp,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 600),
                        child: CustomTextField(
                          controller: nameController,
                          hintText: localizations.fullName,
                          prefixIcon: Icon(Icons.person, color: textColor.withOpacity(0.6)),
                          validator: (value) => value!.isEmpty ? localizations.pleaseEnterYourName : null,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          textColor: textColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 700),
                        child: CustomTextField(
                          controller: emailController,
                          hintText: localizations.email,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icon(Icons.email, color: textColor.withOpacity(0.6)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterYourEmail;
                            }
                            String emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
                            if (!RegExp(emailPattern).hasMatch(value)) {
                              return localizations.invalidEmail;
                            }
                            return null;
                          },
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          textColor: textColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 800),
                        child: CustomTextField(
                          controller: passwordController,
                          hintText: localizations.password,
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(Icons.lock, color: textColor.withOpacity(0.6)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: textColor.withOpacity(0.6),
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) => value!.length < 6 ? localizations.passwordTooShort : null,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          textColor: textColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 900),
                        child: CustomTextField(
                          controller: confirmPasswordController,
                          hintText: localizations.confirmPassword,
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Icon(Icons.lock_outline, color: textColor.withOpacity(0.6)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: textColor.withOpacity(0.6),
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) => value != passwordController.text ? localizations.passwordsDoNotMatch : null,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          textColor: textColor,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      state is AuthLoading
                          ? CircularProgressIndicator(color: accentColor)
                          : FadeInUp(
                        delay: const Duration(milliseconds: 1000),
                        child: CustomButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().registerWithEmail(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                nameController.text.trim(),
                              );
                            }
                          },
                          text: localizations.signUp,
                          backgroundColor: accentColor,
                          textColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      state is AuthLoading
                          ? const SizedBox()
                          : FadeInUp(
                        delay: const Duration(milliseconds: 1100),
                        child: GoogleSignInButton(
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          textColor: textColor,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      FadeInUp(
                        delay: const Duration(milliseconds: 1200),
                        child: AlreadyHaveAccountText(
                          textColor: textColor,
                          accentColor: accentColor,
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
    );
  }
}