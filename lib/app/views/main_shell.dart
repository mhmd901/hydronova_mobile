import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/main_nav_controller.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/app/views/home_view.dart';
import 'package:hydronova_mobile/app/views/profile_view.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavController());
    final pages = <Widget>[
      const HomeView(),
      ProfileView(),
    ];
    final titles = ['Home', 'Profile'];

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(titles[controller.selectedIndex.value]),
          actions: [
            if (controller.selectedIndex.value == 0)
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.bluetoothDevices),
                icon: const Icon(Icons.bluetooth),
                label: const Text('Connect'),
              ),
          ],
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
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
