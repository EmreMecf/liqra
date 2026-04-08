// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiMessageDtoImpl _$$AiMessageDtoImplFromJson(Map<String, dynamic> json) =>
    _$AiMessageDtoImpl(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      mode: json['mode'] as String?,
    );

Map<String, dynamic> _$$AiMessageDtoImplToJson(_$AiMessageDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'mode': instance.mode,
    };
