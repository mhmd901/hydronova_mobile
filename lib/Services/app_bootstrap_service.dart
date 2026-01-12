import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppBootstrapService extends GetxService {
  static const String onboardingKey = 'onboarding_done';

  final GetStorage _storage = GetStorage();

  Future<bool> isOnboardingDone() async {
    return _storage.read<bool>(onboardingKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    await _storage.write(onboardingKey, true);
  }
}
