// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiRequestDtoImpl _$$AiRequestDtoImplFromJson(Map<String, dynamic> json) =>
    _$AiRequestDtoImpl(
      systemPrompt: json['systemPrompt'] as String,
      message: json['message'] as String,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2048,
    );

Map<String, dynamic> _$$AiRequestDtoImplToJson(_$AiRequestDtoImpl instance) =>
    <String, dynamic>{
      'systemPrompt': instance.systemPrompt,
      'message': instance.message,
      'history': instance.history,
      'maxTokens': instance.maxTokens,
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
