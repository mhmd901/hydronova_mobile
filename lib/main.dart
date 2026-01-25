import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hydronova_mobile/Core/Network/api_service.dart';
import 'package:hydronova_mobile/Core/Network/token_provider.dart';
import 'package:hydronova_mobile/Services/app_bootstrap_service.dart';
import 'package:hydronova_mobile/app/controllers/bluetooth_controller.dart';
import 'package:hydronova_mobile/app/controllers/main_nav_controller.dart';
import 'package:hydronova_mobile/app/routes/app_pages.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';
import 'package:hydronova_mobile/features/assistant/assistant_controller.dart';
import 'package:hydronova_mobile/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  Get.put(ApiService(), permanent: true);
  Get.put(TokenProvider(), permanent: true);
  Get.put(AppBootstrapService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(MainNavController(), permanent: true);
  Get.put(AssistantController(), permanent: true);
  Get.put(BluetoothController(), permanent: true);
  runApp(const MyApp(initialRoute: AppRoutes.splash));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    );
  }
}
