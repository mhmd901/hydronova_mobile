import 'package:get/get.dart';
import 'package:hydronova_mobile/features/profile/controllers/change_password_controller.dart';
import 'package:hydronova_mobile/features/profile/services/profile_service.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileService>(() => ProfileService(), fenix: true);
    Get.lazyPut<ChangePasswordController>(() => ChangePasswordController());
  }
}
