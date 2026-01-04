import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final AuthStorage _storage = AuthStorage();

  Map<String, dynamic>? _readUser() {
    return _storage.getUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = _readUser();
    final name = (user?['name'] ?? '').toString().trim();
    final email = (user?['email'] ?? '').toString().trim();
    final displayName = name.isNotEmpty ? name : 'User';
    final displayEmail = email.isNotEmpty ? email : '-';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              displayEmail,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await Get.find<AuthService>().logout();
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
