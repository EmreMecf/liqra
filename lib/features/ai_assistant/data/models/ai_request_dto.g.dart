// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiRequestDtoImpl _$$AiRequestDtoImplFromJson(Map<String, dynamic> json) =>
    _$AiRequestDtoImpl(
      message: json['message'] as String,
      mode: json['mode'] as String,
      context: AiContextDto.fromJson(json['context'] as Map<String, dynamic>),
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$AiRequestDtoImplToJson(_$AiRequestDtoImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'mode': instance.mode,
      'context': instance.context,
      'history': instance.history,
    };

_$AiContextDtoImpl _$$AiContextDtoImplFromJson(Map<String, dynamic> json) =>
    _$AiContextDtoImpl(
      riskProfile: json['riskProfile'] as String,
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      monthlyExpenses: (json['monthlyExpenses'] as num).toDouble(),
      netCash: (json['netCash'] as num).toDouble(),
      portfolioSummary: json['portfolioSummary'] as String,
      transactionsSummary: json['transactionsSummary'] as String,
      goalTitle: json['goalTitle'] as String?,
      goalProgress: (json['goalProgress'] as num?)?.toDouble(),
      goalDeadline: json['goalDeadline'] as String?,
    );

Map<String, dynamic> _$$AiContextDtoImplToJson(_$AiContextDtoImpl instance) =>
    <String, dynamic>{
      'riskProfile': instance.riskProfile,
      'monthlyIncome': instance.monthlyIncome,
      'monthlyExpenses': instance.monthlyExpenses,
      'netCash': instance.netCash,
      'portfolioSummary': instance.portfolioSummary,
      'transactionsSummary': instance.transactionsSummary,
      'goalTitle': instance.goalTitle,
      'goalProgress': instance.goalProgress,
      'goalDeadline': instance.goalDeadline,
    };

_$AiResponseDtoImpl _$$AiResponseDtoImplFromJson(Map<String, dynamic> json) =>
    _$AiResponseDtoImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      inputTokens: (json['inputTokens'] as num?)?.toInt(),
      outputTokens: (json['outputTokens'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AiResponseDtoImplToJson(_$AiResponseDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
    };
