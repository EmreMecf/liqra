import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

abstract class SubscriptionDataSource {
  Future<List<SubscriptionModel>> getSubscriptions(String userId);
  Future<void> addSubscription(SubscriptionModel model);
  Future<void> updateSubscription(SubscriptionModel model);
  Future<void> deleteSubscription(String userId, String subscriptionId);
  Future<void> toggleActive(String userId, String subscriptionId, bool isActive);
}

class SubscriptionFirestoreDataSource implements SubscriptionDataSource {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('subscriptions');

  @override
  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    final snap = await _col(userId)
        .orderBy('nextBillingDate')
        .get();
    return snap.docs
        .map((d) => SubscriptionModel.fromFirestore(d))
        .toList();
  }

  @override
  Future<void> addSubscription(SubscriptionModel model) async {
    await _col(model.userId).doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> updateSubscription(SubscriptionModel model) async {
    await _col(model.userId).doc(model.id).update(model.toFirestore());
  }

  @override
  Future<void> deleteSubscription(String userId, String subscriptionId) async {
    await _col(userId).doc(subscriptionId).delete();
  }

  @override
  Future<void> toggleActive(
    String userId,
    String subscriptionId,
    bool isActive,
  ) async {
    await _col(userId).doc(subscriptionId).update({'isActive': isActive});
  }
}
