import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';

class RegistrationController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> register() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await _authService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (result.message.isNotEmpty) {
        Get.snackbar('Success', result.message);
      }
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Registration Failed', message);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
