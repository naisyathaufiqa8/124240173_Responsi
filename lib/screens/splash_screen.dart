import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Brief minimal delay for graceful splash branding
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final loggedIn = await SessionService.isLoggedIn();
    final userId = await SessionService.getUserId();

    if (!mounted) return;

    if (loggedIn && userId != null) {
      // Pre-load user wishlist
      await Provider.of<WishlistProvider>(context, listen: false).loadWishlist(userId);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.antique.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: AppColors.evergreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ShoppingHub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Curated Goods & Essentials',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.fundySlate,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.evergreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
