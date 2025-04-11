import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (context) => AuthCubit(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go('/interest');
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      child: const Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SlideInLeft(
                            delay: const Duration(milliseconds: 500),
                            child: CustomTextField(
                              controller: emailController,
                              hintText: "Email Address",
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your email";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          SlideInRight(
                            delay: const Duration(milliseconds: 600),
                            child: CustomTextField(
                              controller: passwordController,
                              hintText: "Password",
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    state is AuthLoading
                        ? const CircularProgressIndicator()
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
                        text: "Login",
                      ),
                    ),
                    const SizedBox(height: 50),
                    if (state is! AuthLoading) const GoogleSignInButton(),
                    const SizedBox(height: 50),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: const DoNotHaveAccountText(),
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
