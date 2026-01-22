import 'package:get/get.dart';

import '../middleware/auth_middleware.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/auth/bindings/registration_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/profile/bindings/change_password_binding.dart';
import '../../features/profile/bindings/edit_profile_binding.dart';
import '../views/bluetooth_devices_page.dart';
import '../views/change_password_view.dart';
import '../views/edit_profile_view.dart';
import '../views/home_view.dart';
import '../views/main_shell.dart';
import '../../Views/onboarding_page.dart';
import '../../Views/splash_bootstrap_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashBootstrapPage(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegistrationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShell(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.bluetoothDevices,
      page: () => const BluetoothDevicesPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfileView(),
      binding: EditProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => ChangePasswordView(),
      binding: ChangePasswordBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
