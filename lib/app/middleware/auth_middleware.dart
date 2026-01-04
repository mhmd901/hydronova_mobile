import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';

class AuthMiddleware extends GetMiddleware {
  AuthMiddleware({super.priority = 0});

  final AuthService _authService = Get.find<AuthService>();

  @override
  RouteSettings? redirect(String? route) {
    final hasToken = _authService.isLoggedIn;

    if (hasToken &&
        (route == AppRoutes.login ||
            route == AppRoutes.register ||
            route == AppRoutes.splash)) {
      return const RouteSettings(name: AppRoutes.main);
    }

    if (!hasToken && (route == AppRoutes.main || route == AppRoutes.home)) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
