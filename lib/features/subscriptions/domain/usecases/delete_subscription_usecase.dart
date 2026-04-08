import '../../../../core/utils/result.dart';
import '../repositories/subscription_repository.dart';

class DeleteSubscriptionUseCase {
  final SubscriptionRepository _repository;
  const DeleteSubscriptionUseCase(this._repository);

  Future<Result<void>> call(String userId, String subscriptionId) =>
      _repository.deleteSubscription(userId, subscriptionId);
}
