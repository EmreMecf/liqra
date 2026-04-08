import 'package:flutter/foundation.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';
import '../../domain/usecases/add_subscription_usecase.dart';
import '../../domain/usecases/update_subscription_usecase.dart';
import '../../domain/usecases/delete_subscription_usecase.dart';
import '../../domain/usecases/toggle_subscription_usecase.dart';
import 'subscription_state.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final GetSubscriptionsUseCase    _getSubscriptions;
  final AddSubscriptionUseCase     _addSubscription;
  final UpdateSubscriptionUseCase  _updateSubscription;
  final DeleteSubscriptionUseCase  _deleteSubscription;
  final ToggleSubscriptionUseCase  _toggleSubscription;

  SubscriptionState _state = const SubscriptionInitial();
  SubscriptionState get state => _state;

  SubscriptionViewModel({
    required GetSubscriptionsUseCase    getSubscriptions,
    required AddSubscriptionUseCase     addSubscription,
    required UpdateSubscriptionUseCase  updateSubscription,
    required DeleteSubscriptionUseCase  deleteSubscription,
    required ToggleSubscriptionUseCase  toggleSubscription,
  })  : _getSubscriptions   = getSubscriptions,
        _addSubscription    = addSubscription,
        _updateSubscription = updateSubscription,
        _deleteSubscription = deleteSubscription,
        _toggleSubscription = toggleSubscription;

  // ── Kısayollar ────────────────────────────────────────────────────────────

  List<SubscriptionEntity> get subscriptions => _state.subscriptions;

  SubscriptionLoaded? get _loaded =>
      _state is SubscriptionLoaded ? _state as SubscriptionLoaded : null;

  double get totalMonthly  => _loaded?.totalMonthly ?? 0;
  double get totalYearly   => _loaded?.totalYearly  ?? 0;
  int    get activeCount   => _loaded?.activeCount  ?? 0;

  // ── Aksiyonlar ────────────────────────────────────────────────────────────

  Future<void> load(String userId) async {
    _state = const SubscriptionLoading();
    notifyListeners();

    final result = await _getSubscriptions(userId);
    _state = result.when(
      success: (list) => SubscriptionLoaded(list),
      failure: (f)    => SubscriptionError(f.message),
    );
    notifyListeners();
  }

  Future<bool> add(SubscriptionEntity subscription) async {
    final result = await _addSubscription(subscription);
    return result.when(
      success: (_) {
        if (_state is SubscriptionLoaded) {
          final list = [...(_state as SubscriptionLoaded).subscriptions, subscription]
            ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
          _state = SubscriptionLoaded(list);
          notifyListeners();
        }
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> update(SubscriptionEntity subscription) async {
    final result = await _updateSubscription(subscription);
    return result.when(
      success: (_) {
        if (_state is SubscriptionLoaded) {
          final list = (_state as SubscriptionLoaded)
              .subscriptions
              .map((s) => s.id == subscription.id ? subscription : s)
              .toList()
            ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
          _state = SubscriptionLoaded(list);
          notifyListeners();
        }
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> delete(String userId, String subscriptionId) async {
    final result = await _deleteSubscription(userId, subscriptionId);
    return result.when(
      success: (_) {
        if (_state is SubscriptionLoaded) {
          final list = (_state as SubscriptionLoaded)
              .subscriptions
              .where((s) => s.id != subscriptionId)
              .toList();
          _state = SubscriptionLoaded(list);
          notifyListeners();
        }
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<void> toggle(String userId, String subscriptionId, bool isActive) async {
    final result = await _toggleSubscription(userId, subscriptionId, isActive);
    result.onSuccess((_) {
      if (_state is SubscriptionLoaded) {
        final list = (_state as SubscriptionLoaded).subscriptions.map((s) {
          return s.id == subscriptionId ? s.copyWith(isActive: isActive) : s;
        }).toList();
        _state = SubscriptionLoaded(list);
        notifyListeners();
      }
    });
  }
}
