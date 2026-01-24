import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/Core/Network/show_success_dialog.dart';
import 'package:hydronova_mobile/app/controllers/main_nav_controller.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/profile/services/profile_service.dart';

class ChangePasswordController extends GetxController {
  final ProfileService _service = Get.find<ProfileService>();

  final TextEditingController currentController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final RxBool isSaving = false.obs;

  void _goToProfile() {
    final navController = Get.find<MainNavController>();
    navController.changeTab(2);
    Get.offAllNamed(AppRoutes.main);
  }

  Future<void> changePassword() async {
    if (isSaving.value) return;
    final newPassword = newController.text.trim();
    final confirmation = confirmController.text.trim();
    if (newPassword.length < 8) {
      Get.snackbar('Validation', 'Password must be at least 8 characters');
      return;
    }
    if (newPassword != confirmation) {
      Get.snackbar('Validation', 'Passwords do not match');
      return;
    }

    isSaving.value = true;
    try {
      final result = await _service.changePassword(
        currentPassword: currentController.text,
        newPassword: newPassword,
        confirmation: confirmation,
      );
      if (result.success) {
        final message =
            result.message.isNotEmpty ? result.message : 'Password updated';
        final context = Get.context;
        if (context != null) {
          showSuccessDialog(context, 'Success', message, _goToProfile);
        } else {
          Get.snackbar('Success', message);
          _goToProfile();
        }
      } else {
        Get.snackbar('Update Failed', result.message);
      }
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
