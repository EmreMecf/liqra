import '../../../../core/utils/result.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionsUseCase {
  final SubscriptionRepository _repository;
  const GetSubscriptionsUseCase(this._repository);

  Future<Result<List<SubscriptionEntity>>> call(String userId) =>
      _repository.getSubscriptions(userId);
}
