import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/Routes/app_page.dart';
import 'package:hydronova_mobile/Routes/app_routes.dart';

import 'Views/registrationpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.register,
      getPages: AppPage.pages,
      home: const Registration(),
    );
  }
}
