// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionDtoImpl _$$TransactionDtoImplFromJson(Map<String, dynamic> json) =>
    _$TransactionDtoImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      date: json['date'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$TransactionDtoImplToJson(
  _$TransactionDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'amount': instance.amount,
  'category': instance.category,
  'type': instance.type,
  'source': instance.source,
  'date': instance.date,
  'note': instance.note,
};

_$MonthlySummaryDtoImpl _$$MonthlySummaryDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MonthlySummaryDtoImpl(
  totalIncome: (json['totalIncome'] as num).toDouble(),
  totalExpenses: (json['totalExpenses'] as num).toDouble(),
  netCash: (json['netCash'] as num).toDouble(),
  byCategory: (json['byCategory'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
);

Map<String, dynamic> _$$MonthlySummaryDtoImplToJson(
  _$MonthlySummaryDtoImpl instance,
) => <String, dynamic>{
  'totalIncome': instance.totalIncome,
  'totalExpenses': instance.totalExpenses,
  'netCash': instance.netCash,
  'byCategory': instance.byCategory,
  'year': instance.year,
  'month': instance.month,
};
