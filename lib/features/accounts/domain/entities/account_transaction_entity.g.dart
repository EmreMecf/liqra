// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_transaction_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountTransactionEntityImpl _$$AccountTransactionEntityImplFromJson(
  Map<String, dynamic> json,
) => _$AccountTransactionEntityImpl(
  id: json['id'] as String,
  accountId: json['accountId'] as String,
  userId: json['userId'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  date: DateTime.parse(json['date'] as String),
  type: json['type'] as String,
  category: json['category'] as String,
  isInstallment: json['isInstallment'] as bool? ?? false,
  installmentCount: (json['installmentCount'] as num?)?.toInt() ?? 1,
  installmentNumber: (json['installmentNumber'] as num?)?.toInt() ?? 1,
  merchantName: json['merchantName'] as String?,
  statementId: json['statementId'] as String?,
  source: json['source'] as String? ?? 'manual',
);

Map<String, dynamic> _$$AccountTransactionEntityImplToJson(
  _$AccountTransactionEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'accountId': instance.accountId,
  'userId': instance.userId,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'type': instance.type,
  'category': instance.category,
  'isInstallment': instance.isInstallment,
  'installmentCount': instance.installmentCount,
  'installmentNumber': instance.installmentNumber,
  'merchantName': instance.merchantName,
  'statementId': instance.statementId,
  'source': instance.source,
};
