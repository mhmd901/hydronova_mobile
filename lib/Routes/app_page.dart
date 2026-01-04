import 'package:get/get.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/views/login_view.dart';
import 'package:hydronova_mobile/features/auth/views/register_view.dart';

import '../features/auth/bindings/login_binding.dart';
import '../features/auth/bindings/registration_binding.dart';

class AppPage {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegistrationBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
  ];
}
