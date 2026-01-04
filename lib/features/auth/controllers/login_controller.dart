import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> login() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (result.message.isNotEmpty) {
        Get.snackbar('Success', result.message);
      }
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Login Failed', message);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
