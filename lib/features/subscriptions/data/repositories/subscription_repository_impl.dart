import '../../../../core/utils/result.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource _dataSource;
  const SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<SubscriptionEntity>>> getSubscriptions(String userId) async {
    try {
      final models = await _dataSource.getSubscriptions(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure(ServerFailure('Abonelikler yüklenemedi: $e'));
    }
  }

  @override
  Future<Result<void>> addSubscription(SubscriptionEntity subscription) async {
    try {
      await _dataSource.addSubscription(SubscriptionModel.fromEntity(subscription));
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Abonelik eklenemedi: $e'));
    }
  }

  @override
  Future<Result<void>> updateSubscription(SubscriptionEntity subscription) async {
    try {
      await _dataSource.updateSubscription(SubscriptionModel.fromEntity(subscription));
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Abonelik güncellenemedi: $e'));
    }
  }

  @override
  Future<Result<void>> deleteSubscription(
    String userId,
    String subscriptionId,
  ) async {
    try {
      await _dataSource.deleteSubscription(userId, subscriptionId);
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Abonelik silinemedi: $e'));
    }
  }

  @override
  Future<Result<void>> toggleActive(
    String userId,
    String subscriptionId,
    bool isActive,
  ) async {
    try {
      await _dataSource.toggleActive(userId, subscriptionId, isActive);
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Durum güncellenemedi: $e'));
    }
  }
}
