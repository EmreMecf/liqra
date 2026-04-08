import '../../../../core/utils/result.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class AddSubscriptionUseCase {
  final SubscriptionRepository _repository;
  const AddSubscriptionUseCase(this._repository);

  Future<Result<void>> call(SubscriptionEntity subscription) =>
      _repository.addSubscription(subscription);
}
