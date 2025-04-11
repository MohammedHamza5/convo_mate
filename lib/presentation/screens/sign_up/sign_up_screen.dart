import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthCubit(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go('/interest');
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeInDown(
                        delay: const Duration(milliseconds: 500),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 600),
                        child: CustomTextField(
                          controller: nameController,
                          hintText: "Full Name",
                          prefixIcon: const Icon(Icons.person),
                          validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 700),
                        child: CustomTextField(
                          controller: emailController,
                          hintText: "Email",
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "الرجاء إدخال البريد الإلكتروني";
                            }
                            String emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
                            if (!RegExp(emailPattern).hasMatch(value)) {
                              return "عنوان البريد الإلكتروني غير صالح";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 800),
                        child: CustomTextField(
                          controller: passwordController,
                          hintText: "Password",
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) => value!.length < 6 ? "Password must be at least 6 characters" : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 900),
                        child: CustomTextField(
                          controller: confirmPasswordController,
                          hintText: "Confirm Password",
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) => value != passwordController.text ? "Passwords do not match" : null,
                        ),
                      ),
                      const SizedBox(height: 40),
                      state is AuthLoading
                          ? const CircularProgressIndicator()
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
                          text: "Sign Up",
                        ),
                      ),
                      const SizedBox(height: 40),
                      state is AuthLoading
                          ? const SizedBox()
                          : FadeInUp(
                        delay: const Duration(milliseconds: 1100),
                        child: const GoogleSignInButton(),
                      ),
                      const SizedBox(height: 40),
                      FadeInUp(
                        delay: const Duration(milliseconds: 1200),
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const AlreadyHaveAccountText(),
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
