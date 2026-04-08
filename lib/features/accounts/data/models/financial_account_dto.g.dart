// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FinancialAccountDtoImpl _$$FinancialAccountDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FinancialAccountDtoImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
  bank: json['bank'] as String,
  currency: json['currency'] as String,
  createdAt: json['createdAt'] as String,
  balance: (json['balance'] as num?)?.toDouble(),
  iban: json['iban'] as String?,
  maskedAccountNumber: json['maskedAccountNumber'] as String?,
  creditLimit: (json['creditLimit'] as num?)?.toDouble(),
  usedAmount: (json['usedAmount'] as num?)?.toDouble(),
  statementBalance: (json['statementBalance'] as num?)?.toDouble(),
  minimumPayment: (json['minimumPayment'] as num?)?.toDouble(),
  statementClosingDay: (json['statementClosingDay'] as num?)?.toInt(),
  paymentDueDay: (json['paymentDueDay'] as num?)?.toInt(),
  maskedCardNumber: json['maskedCardNumber'] as String?,
);

Map<String, dynamic> _$$FinancialAccountDtoImplToJson(
  _$FinancialAccountDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'type': instance.type,
  'name': instance.name,
  'bank': instance.bank,
  'currency': instance.currency,
  'createdAt': instance.createdAt,
  'balance': instance.balance,
  'iban': instance.iban,
  'maskedAccountNumber': instance.maskedAccountNumber,
  'creditLimit': instance.creditLimit,
  'usedAmount': instance.usedAmount,
  'statementBalance': instance.statementBalance,
  'minimumPayment': instance.minimumPayment,
  'statementClosingDay': instance.statementClosingDay,
  'paymentDueDay': instance.paymentDueDay,
  'maskedCardNumber': instance.maskedCardNumber,
};
