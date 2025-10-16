// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:quickbite/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container with theme-aware colors
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.white : AppColors.primaryBlue)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: isDark ? AppColors.primaryBlue : Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App name with theme-aware color
            Text(
              'QuickBite',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline with theme-aware color
            Text(
              'Your Campus Marketplace',
              style: TextStyle(
                color: theme.colorScheme.primary.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
