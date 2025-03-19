import 'package:flutter/material.dart';
import '../../../styles/text_styles.dart';

class DoNotHaveAccountText extends StatelessWidget {
  const DoNotHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Don\'t have an account yet?',
              style: TextStyles.bodyText,
            ),
            TextSpan(
              text: ' Sign Up',
              style: TextStyles.linkText,
            ),
          ],
        ),
      ),
    );
  }
}