import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_cubit.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
      icon: Icon(Icons.login),
      label: Text("التسجيل بحساب جوجل"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }
}