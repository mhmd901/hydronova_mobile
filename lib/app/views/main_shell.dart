import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/main_nav_controller.dart';
import 'package:hydronova_mobile/app/views/home_view.dart';
import 'package:hydronova_mobile/app/views/profile_view.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/assistant/assistant_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainNavController>();
    final pages = <Widget>[
      const HomeView(),
      const AssistantPage(),
      ProfileView(),
    ];
    final titles = ['Home', 'Assistant', 'Profile'];

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(titles[controller.selectedIndex.value]),
          actions: controller.selectedIndex.value == 0
              ? [
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.bluetooth),
                    tooltip: 'Bluetooth',
                    icon: const Icon(Icons.bluetooth),
                  ),
                ]
              : null,
        ),
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
