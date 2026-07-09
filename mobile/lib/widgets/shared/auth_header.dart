import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Branded header shared by the login and signup screens: a badge logo
/// + "Stud/Connect" wordmark, echoing the indigo badge used on the web
/// app's own header/login page so both clients read as the same product.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
            children: [
              const TextSpan(text: 'Stud'),
              TextSpan(
                text: 'Connect',
                style: TextStyle(color: AppColors.brand600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate600),
        ),
      ],
    );
  }
}
