import 'package:get/get.dart';

import '../middleware/auth_middleware.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/auth/bindings/registration_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../views/home_view.dart';
import '../views/main_shell.dart';
import '../views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      middlewares: [AuthMiddleware()],
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
  ];
}
