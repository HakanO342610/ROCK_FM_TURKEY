import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.music_note, color: AppColors.gold, size: 60),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'RockFM',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
                letterSpacing: 4,
                height: 1,
              ),
            ),
            const Text(
              'Turkey',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.goldBright,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '7/24 CANLI ROCK YAYINI',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
