import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // استيراد GoRouter للتنقل بين الصفحات
import '../../../styles/text_styles.dart';

class DoNotHaveAccountText extends StatelessWidget {
  const DoNotHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/signup'),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account yet?",
              style: TextStyles.bodyText.copyWith(color: Colors.grey[700]), // تحسين لون النص
            ),
            TextSpan(
              text: ' Sign Up',
              style: TextStyles.linkText.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
