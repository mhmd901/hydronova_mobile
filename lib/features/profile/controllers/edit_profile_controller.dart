import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';
import 'package:hydronova_mobile/features/profile/services/profile_service.dart';

class EditProfileController extends GetxController {
  final ProfileService _service = Get.find<ProfileService>();
  final AuthStorage _storage = AuthStorage();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = _storage.getUser();
    nameController.text = (user?['name'] ?? '').toString();
    emailController.text = (user?['email'] ?? '').toString();
  }

  Future<void> saveProfile() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final result = await _service.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      if (result.success) {
        final message =
            result.message.isNotEmpty ? result.message : 'Profile updated';
        Get.snackbar('Success', message);
        Get.back();
      } else {
        Get.snackbar('Update Failed', result.message);
      }
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
