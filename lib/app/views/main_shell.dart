import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/main_nav_controller.dart';
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
          title: Text(titles[controller.selectedIndex.value]),
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
