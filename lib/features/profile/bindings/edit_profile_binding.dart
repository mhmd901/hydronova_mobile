import 'package:get/get.dart';
import 'package:hydronova_mobile/features/profile/controllers/edit_profile_controller.dart';
import 'package:hydronova_mobile/features/profile/services/profile_service.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileService>(() => ProfileService(), fenix: true);
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
