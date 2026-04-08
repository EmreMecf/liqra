import '../../domain/entities/subscription_entity.dart';

sealed class SubscriptionState {
  const SubscriptionState();
}

final class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

final class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionEntity> subscriptions;
  const SubscriptionLoaded(this.subscriptions);

  List<SubscriptionEntity> get active =>
      subscriptions.where((s) => s.isActive).toList();

  List<SubscriptionEntity> get inactive =>
      subscriptions.where((s) => !s.isActive).toList();

  List<SubscriptionEntity> get upcoming =>
      active
          .where((s) => s.daysUntilBilling >= 0 && s.daysUntilBilling <= 30)
          .toList()
        ..sort((a, b) => a.daysUntilBilling.compareTo(b.daysUntilBilling));

  double get totalMonthly =>
      active.fold(0.0, (sum, s) => sum + s.monthlyEquivalent);

  double get totalYearly => totalMonthly * 12;

  int get activeCount => active.length;
}

final class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
}

// Uzantı — herhangi bir state'ten güvenli erişim
extension SubscriptionStateX on SubscriptionState {
  List<SubscriptionEntity> get subscriptions =>
      this is SubscriptionLoaded ? (this as SubscriptionLoaded).subscriptions : [];

  bool get isLoading => this is SubscriptionLoading;
}
