import 'package:get/get.dart';
import 'package:hydronova_mobile/Routes/app_routes.dart';
import 'package:hydronova_mobile/Views/login_page.dart';
import 'package:hydronova_mobile/Views/registrationpage.dart';

import '../Binding/login_binding.dart';
import '../Binding/registration_binding.dart';

class AppPage {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.register,
      page: () => const Registration(),
      binding: RegistrationBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const Login(),
      binding: LoginBinding(),
    ),
  ];
}
