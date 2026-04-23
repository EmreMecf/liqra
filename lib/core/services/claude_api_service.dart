import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'feature_flag_service.dart';

/// Doğrudan Anthropic API istemcisi — backend gerektirmez.
///
/// API anahtarı öncelik sırası:
///   1. FlutterSecureStorage (`anthropic_api_key`)
///   2. Compile-time dart-define (`--dart-define=ANTHROPIC_KEY=...`)
///   3. Boş ise hata fırlatır
///
/// Model adları Firebase Remote Config'den gelir:
///   claude_chat_model → varsayılan: claude-sonnet-4-6
///   claude_fast_model → varsayılan: claude-haiku-4-5-20251001
class ClaudeApiService {
  ClaudeApiService._();
  static final instance = ClaudeApiService._();

  static const _prefKey    = 'anthropic_api_key';
  static const _baseUrl    = 'https://api.anthropic.com';
  static const _apiVersion = '2023-06-01';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String get _chatModel {
    final remote = FeatureFlagService.instance.getString('claude_chat_model');
    return remote.isNotEmpty ? remote : 'claude-sonnet-4-6';
  }

  String get _fastModel {
    final remote = FeatureFlagService.instance.getString('claude_fast_model');
    return remote.isNotEmpty ? remote : 'claude-haiku-4-5-20251001';
  }

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout:    const Duration(seconds: 30),
      headers: {'content-type': 'application/json'},
    ),
  );

  // ── API Key Yönetimi ──────────────────────────────────────────────────────

  /// Kayıtlı API key'i döner (null = henüz girilmedi)
  Future<String?> getApiKey() async {
    final key = await _storage.read(key: _prefKey) ?? '';
    if (key.isNotEmpty) return key;
    // Compile-time dart-define fallback
    const defined = String.fromEnvironment('ANTHROPIC_KEY');
    if (defined.isNotEmpty) return defined;
    return null;
  }

  /// API key'i güvenli depoya yaz
  Future<void> setApiKey(String key) async {
    await _storage.write(key: _prefKey, value: key.trim());
    debugPrint('[ClaudeAPI] API key kaydedildi.');
  }

  /// API key sil
  Future<void> clearApiKey() async {
    await _storage.delete(key: _prefKey);
  }

  /// API key girilmiş mi?
  Future<bool> hasApiKey() async => (await getApiKey()) != null;

  // ── Chat (AI Asistan) ─────────────────────────────────────────────────────

  /// Metin tabanlı sohbet — AI asistan için
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 2048,
  }) async {
    final key = await _resolvedKey();

    try {
      final resp = await _dio.post(
        '/v1/messages',
        options: Options(headers: {
          'x-api-key':         key,
          'anthropic-version': _apiVersion,
        }),
        data: {
          'model':      _chatModel,
          'max_tokens': maxTokens,
          'system':     systemPrompt,
          'messages':   messages,
        },
      );
      return _extractText(resp.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Döküman / Görsel Analizi (OCR) ────────────────────────────────────────

  /// Görsel veya PDF'i analiz et — OCR için
  ///
  /// [mediaType]: 'image/jpeg' | 'image/png' | 'image/webp' | 'application/pdf'
  Future<String> analyzeDocument({
    required String base64Data,
    required String mediaType,
    required String prompt,
    int maxTokens = 1024,
  }) async {
    final key        = await _resolvedKey();
    final isImage    = mediaType.startsWith('image/');

    final sourceBlock = <String, dynamic>{
      'type':       'base64',
      'media_type': mediaType,
      'data':       base64Data,
    };

    final contentBlock = isImage
        ? {'type': 'image', 'source': sourceBlock}
        : {'type': 'document', 'source': sourceBlock};

    try {
      final resp = await _dio.post(
        '/v1/messages',
        options: Options(headers: {
          'x-api-key':           key,
          'anthropic-version':   _apiVersion,
          'anthropic-beta':      'pdfs-2024-09-25',
        }),
        data: {
          'model':      _fastModel,
          'max_tokens': maxTokens,
          'messages': [
            {
              'role': 'user',
              'content': [
                contentBlock,
                {'type': 'text', 'text': prompt},
              ],
            }
          ],
        },
      );
      return _extractText(resp.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  Future<String> _resolvedKey() async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw Exception(
        'Anthropic API anahtarı bulunamadı.\n'
        'Profil > API Anahtarı bölümünden ekleyin.',
      );
    }
    return key;
  }

  String _extractText(dynamic data) {
    final content = (data['content'] as List?)?.cast<Map<String, dynamic>>();
    if (content == null || content.isEmpty) return '';
    return content
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String? ?? '')
        .join('\n');
  }

  Exception _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    final msg    = e.response?.data?['error']?['message'] as String?;

    debugPrint('[ClaudeAPI] HTTP $status: $msg');

    if (status == 401) {
      return Exception('API anahtarı geçersiz. Profil ekranından güncelleyin.');
    }
    if (status == 429) {
      return Exception('İstek limiti aşıldı. Biraz bekleyin.');
    }
    if (status != null && status >= 500) {
      return Exception('Anthropic sunucu hatası. Lütfen tekrar deneyin.');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception('İnternet bağlantısı yok.');
    }
    return Exception(msg ?? 'AI servisi hatası: ${e.message}');
  }
}
