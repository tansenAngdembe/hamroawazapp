import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/debug_helper.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAuth();
    });
  }

  Future<void> _bootstrapAuth() async {
    try {
      final authService = context.read<AuthService>();
      String? accessToken;

      try {
        accessToken = await authService.getAccessToken();
      } catch (e, st) {
        DebugHelper.logError('Splash: token read failed', e, st);
        accessToken = null;
      }

      if (!mounted) return;

      if (accessToken == null || accessToken.isEmpty) {
        context.go('/login');
        return;
      }

      Map<String, dynamic> authResult;
      try {
        authResult = await authService.checkAuth();
      } catch (e, st) {
        DebugHelper.logError('Splash: checkAuth failed (non-fatal)', e, st);
        authResult = {'success': false, 'authenticated': false};
      }

      if (!mounted) return;

      final isAuthenticated = authResult['success'] == true &&
          authResult['authenticated'] == true;

      if (isAuthenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    } catch (e, st) {
      DebugHelper.logError('Splash: bootstrap failed', e, st);
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
