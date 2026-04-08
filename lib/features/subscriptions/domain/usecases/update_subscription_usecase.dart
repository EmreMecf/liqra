import '../../../../core/utils/result.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class UpdateSubscriptionUseCase {
  final SubscriptionRepository _repository;
  const UpdateSubscriptionUseCase(this._repository);

  Future<Result<void>> call(SubscriptionEntity subscription) =>
      _repository.updateSubscription(subscription);
}
