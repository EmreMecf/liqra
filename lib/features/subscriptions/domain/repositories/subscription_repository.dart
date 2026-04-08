import '../../../../core/utils/result.dart';
import '../entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<Result<List<SubscriptionEntity>>> getSubscriptions(String userId);
  Future<Result<void>> addSubscription(SubscriptionEntity subscription);
  Future<Result<void>> updateSubscription(SubscriptionEntity subscription);
  Future<Result<void>> deleteSubscription(String userId, String subscriptionId);
  Future<Result<void>> toggleActive(String userId, String subscriptionId, bool isActive);
}
