import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/widgets/app_widgets.dart';
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withOpacity(0.7)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              await Get.find<AuthService>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
