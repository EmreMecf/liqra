import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'feature_flag_service.dart';

/// Google Gemini AI servisi — resmi google_generative_ai SDK kullanır.
///
/// API key yönetimi:
///   Firebase Remote Config → `gemini_api_key` parametresi
class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  static const _defaultModel = 'gemini-2.0-flash';

  // ── API Key & Model ───────────────────────────────────────────────────────

  String get _apiKey =>
      FeatureFlagService.instance.getString('gemini_api_key');

  /// Remote Config'den model adı okunur; yoksa varsayılan kullanılır.
  String get _model {
    final remote = FeatureFlagService.instance.getString('gemini_model');
    return remote.isNotEmpty ? remote : _defaultModel;
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  // ── Chat (AI Asistan) ─────────────────────────────────────────────────────

  /// Sohbet — sistem promptu + mesaj geçmişi
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 2048,
  }) async {
    _requireKey();

    final model = GenerativeModel(
      model:   _model,
      apiKey:  _apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: maxTokens,
        temperature:     0.7,
      ),
    );

    // Geçmiş mesajları SDK formatına çevir (son mesaj hariç)
    final history = <Content>[];
    for (final m in messages.take(messages.length - 1)) {
      final role = m['role'] == 'assistant' ? 'model' : 'user';
      history.add(Content(role, [TextPart(m['content'] ?? '')]));
    }

    final chat = model.startChat(history: history);

    // Son mesajı gönder
    final lastMessage = messages.last['content'] ?? '';
    try {
      final response = await chat.sendMessage(Content.text(lastMessage));
      return response.text ?? '';
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Görüntü / PDF Analizi (OCR) ───────────────────────────────────────────

  /// base64 görsel veya PDF → analiz metni
  ///
  /// [mimeType]: 'image/jpeg' | 'image/png' | 'image/webp' | 'application/pdf'
  Future<String> analyzeDocument({
    required String base64Data,
    required String mimeType,
    required String prompt,
    int maxTokens = 8192,
  }) async {
    _requireKey();

    final model = GenerativeModel(
      model:  _model,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens:  maxTokens,
        temperature:      0.1,
        responseMimeType: 'application/json',  // Her zaman geçerli JSON döner
      ),
    );

    final bytes = base64Decode(base64Data);

    try {
      final response = await model.generateContent([
        Content.multi([
          DataPart(mimeType, bytes),
          TextPart(prompt),
        ]),
      ]);
      final text = response.text ?? '';
      debugPrint('[GeminiService] Yanıt (ilk 500 karakter): ${text.substring(0, text.length.clamp(0, 500))}');
      return text;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PDF bytes → analiz et (büyük PDF'ler de dahil)
  Future<String> analyzePdfBytes({
    required List<int> pdfBytes,
    required String prompt,
    int maxTokens = 1024,
  }) async {
    return analyzeDocument(
      base64Data: base64Encode(pdfBytes),
      mimeType:   'application/pdf',
      prompt:     prompt,
      maxTokens:  maxTokens,
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  void _requireKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API anahtarı bulunamadı.\n'
        'Firebase Remote Config\'e "gemini_api_key" parametresi ekleyin.',
      );
    }
  }

  /// Gemini hatalarını kullanıcıya gösterilebilir Türkçe mesaja çevirir.
  ///
  /// Önceden `e.message` doğrudan döndürülüyordu; kullanıcı Google'ın ham
  /// İngilizce metnini görüyordu. Kredi bittiğinde ekranda şu çıkıyordu:
  /// "Your prepayment credits are depleted. Please go to AI Studio at
  /// https://ai.studio/projects to manage your project and billing."
  ///
  /// Bu hem anlaşılmaz hem de uygulamanın faturalandırma detayını kullanıcıya
  /// sızdırıyor. Ham mesaj yalnızca log'da kalıyor.
  Exception _handleError(Object e) {
    debugPrint('[GeminiService] Hata: $e');

    if (e is GenerativeAIException) {
      debugPrint('[GeminiService] Ham mesaj: ${e.message}');
      return Exception(_kullaniciMesaji(e.message));
    }

    if (e is Exception) {
      debugPrint('[GeminiService] Ham mesaj: $e');
      return Exception(_kullaniciMesaji(e.toString()));
    }
    return Exception('Yapay zekâ şu an yanıt veremiyor. Lütfen tekrar deneyin.');
  }

  String _kullaniciMesaji(String ham) {
    final m = ham.toLowerCase();

    // Kota, kredi ve faturalandırma — kullanıcının yapabileceği bir şey yok.
    if (m.contains('prepayment') ||
        m.contains('credits are depleted') ||
        m.contains('billing') ||
        m.contains('quota') ||
        m.contains('resource_exhausted') ||
        m.contains('exceeded')) {
      return 'Yapay zekâ şu an kullanılamıyor. Kısa süre içinde tekrar deneyin.';
    }

    // Çok sık istek.
    if (m.contains('rate limit') || m.contains('too many requests') || m.contains('429')) {
      return 'Çok fazla istek gönderildi. Biraz bekleyip tekrar deneyin.';
    }

    // Anahtar sorunu — yapılandırma hatası, kullanıcı çözemez.
    if (m.contains('api key') || m.contains('api_key') || m.contains('permission_denied') ||
        m.contains('unauthenticated')) {
      return 'Yapay zekâ servisi yapılandırılamadı. Sorun bizde, en kısa sürede düzeltilecek.';
    }

    // İçerik güvenlik filtresine takıldı.
    if (m.contains('safety') || m.contains('blocked')) {
      return 'Bu istek yanıtlanamadı. Farklı bir şekilde sormayı deneyin.';
    }

    // Bağlantı.
    if (m.contains('socket') || m.contains('network') || m.contains('timeout') ||
        m.contains('connection')) {
      return 'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.';
    }

    return 'Yapay zekâ şu an yanıt veremiyor. Lütfen tekrar deneyin.';
  }
}
