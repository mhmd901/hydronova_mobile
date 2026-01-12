import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/Services/app_bootstrap_service.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';

class SplashBootstrapPage extends StatefulWidget {
  const SplashBootstrapPage({super.key});

  @override
  State<SplashBootstrapPage> createState() => _SplashBootstrapPageState();
}

class _SplashBootstrapPageState extends State<SplashBootstrapPage> {
  final AppBootstrapService _bootstrapService =
      Get.find<AppBootstrapService>();
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final onboardingDone = await _bootstrapService.isOnboardingDone();
    await _authService.loadToken();
    final hasToken = _authService.isLoggedIn;

    if (!mounted) return;

    if (!onboardingDone) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    Get.offAllNamed(hasToken ? AppRoutes.main : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF7F9FB);
    const primaryColor = Color(0xFF2DAA9E);
    const textColor = Color(0xFF212529);

    return const Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_outlined, size: 48, color: primaryColor),
            SizedBox(height: 12),
            Text(
              'HydroNova',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
