import '../../../../core/utils/result.dart';
import '../repositories/subscription_repository.dart';

class ToggleSubscriptionUseCase {
  final SubscriptionRepository _repository;
  const ToggleSubscriptionUseCase(this._repository);

  Future<Result<void>> call(String userId, String subscriptionId, bool isActive) =>
      _repository.toggleActive(userId, subscriptionId, isActive);
}
