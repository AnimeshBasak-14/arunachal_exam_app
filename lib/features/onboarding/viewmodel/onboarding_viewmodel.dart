import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/service_providers.dart';

final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingViewModel(storage);
});

class OnboardingViewModel extends StateNotifier<bool> {
  final StorageService _storage;

  OnboardingViewModel(this._storage) : super(_storage.isOnboardingCompleted);

  void completeOnboarding() {
    _storage.setOnboardingCompleted(true);
    state = true;
  }
}
