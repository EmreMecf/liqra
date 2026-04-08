import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription_entity.dart';

/// Firestore DTO — abonelik verisi
class SubscriptionModel {
  final String id;
  final String userId;
  final String name;
  final double price;
  final String billingCycle;
  final String nextBillingDate; // ISO 8601
  final String category;
  final int colorValue;
  final String emoji;
  final bool isActive;
  final String? note;
  final String createdAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    required this.colorValue,
    required this.emoji,
    required this.isActive,
    this.note,
    required this.createdAt,
  });

  factory SubscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return SubscriptionModel(
      id:              doc.id,
      userId:          d['userId']          as String? ?? '',
      name:            d['name']            as String? ?? '',
      price:           (d['price'] as num?)?.toDouble() ?? 0,
      billingCycle:    d['billingCycle']    as String? ?? 'monthly',
      nextBillingDate: _tsToIso(d['nextBillingDate']),
      category:        d['category']        as String? ?? 'diğer',
      colorValue:      (d['colorValue']     as int?)   ?? 0xFF0AFFE0,
      emoji:           d['emoji']           as String? ?? '⭐',
      isActive:        d['isActive']        as bool?   ?? true,
      note:            d['note']            as String?,
      createdAt:       _tsToIso(d['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId':          userId,
        'name':            name,
        'price':           price,
        'billingCycle':    billingCycle,
        'nextBillingDate': Timestamp.fromDate(DateTime.parse(nextBillingDate)),
        'category':        category,
        'colorValue':      colorValue,
        'emoji':           emoji,
        'isActive':        isActive,
        if (note != null) 'note': note,
        'createdAt':       Timestamp.fromDate(DateTime.parse(createdAt)),
      };

  SubscriptionEntity toEntity() => SubscriptionEntity(
        id:              id,
        userId:          userId,
        name:            name,
        price:           price,
        billingCycle:    BillingCycle.fromString(billingCycle),
        nextBillingDate: DateTime.parse(nextBillingDate),
        category:        category,
        colorValue:      colorValue,
        emoji:           emoji,
        isActive:        isActive,
        note:            note,
        createdAt:       DateTime.parse(createdAt),
      );

  static SubscriptionModel fromEntity(SubscriptionEntity e) => SubscriptionModel(
        id:              e.id,
        userId:          e.userId,
        name:            e.name,
        price:           e.price,
        billingCycle:    e.billingCycle.name,
        nextBillingDate: e.nextBillingDate.toIso8601String(),
        category:        e.category,
        colorValue:      e.colorValue,
        emoji:           e.emoji,
        isActive:        e.isActive,
        note:            e.note,
        createdAt:       e.createdAt.toIso8601String(),
      );

  static String _tsToIso(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is String)    return v;
    return DateTime.now().toIso8601String();
  }
}
