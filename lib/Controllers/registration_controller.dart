import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/Core/Network/dio_client.dart';
import '../Models/user.dart';
import '../Core/Network/show_success_dialog.dart';

class RegistrationController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  void register() async{
    // Registration logic here

    User user = User(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
    );
    String requestbody = user.toJson();
    var post = await DioClient().getInstance().post('/M_register', data: requestbody);
    if(post.statusCode == 200){
      showSuccessDialog(Get.context!, "Success"," Registration Successful",(){});
    }
    else{
      showSuccessDialog(Get.context!, "Error"," Registration Failed",(){});
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
