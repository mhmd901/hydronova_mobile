// lib/Controllers/login_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/Core/Network/dio_client.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    // Login logic here
    debugPrint(
      "name: , email: ${emailController.text}, password: ${passwordController.text}",
    );

    final requestBody = {
      'email': emailController.text,
      'password': passwordController.text,
    };
    await DioClient().getInstance().post('/M_login', data: requestBody);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
