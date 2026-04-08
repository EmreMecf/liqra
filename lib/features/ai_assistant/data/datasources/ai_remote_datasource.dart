import '../../../../core/error/app_exception.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/ai_request_dto.dart';

/// AI API uzak veri kaynağı — Google Gemini API'ye direkt bağlanır
abstract interface class AiRemoteDataSource {
  Future<AiResponseDto> sendMessage(AiRequestDto request);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final GeminiService _gemini;

  const AiRemoteDataSourceImpl(this._gemini);

  @override
  Future<AiResponseDto> sendMessage(AiRequestDto request) async {
    try {
      final systemPrompt = _buildSystemPrompt(request.mode, request.context);

      // Geçmiş + mevcut mesaj → Gemini format
      final messages = <Map<String, String>>[
        ...request.history.map(
          (h) => {'role': h['role']!, 'content': h['content']!},
        ),
        {'role': 'user', 'content': request.message},
      ];

      final content = await _gemini.chat(
        systemPrompt: systemPrompt,
        messages: messages,
      );

      if (content.isEmpty) {
        throw AppException.server(
          message: 'Gemini boş yanıt döndürdü.',
          statusCode: 200,
        );
      }

      return AiResponseDto(
        id:          DateTime.now().millisecondsSinceEpoch.toString(),
        content:     content,
        timestamp:   DateTime.now().toIso8601String(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(message: e.toString());
    }
  }

  // ── Sistem promptu ────────────────────────────────────────────────────────

  String _buildSystemPrompt(String mode, AiContextDto ctx) {
    final today = DateTime.now();
    final tarih = '${today.day}.${today.month}.${today.year}';

    final base = '''Sen **Liqra** finansal asistanısın. Türk kullanıcısına **Türkçe**, kısa, somut ve samimi yanıtlar veriyorsun. Markdown kullan (başlık, madde, kalın).

📅 Bugün: $tarih

**Kullanıcı Profili:**
• Risk profili: ${ctx.riskProfile}
• Aylık gelir: ${ctx.monthlyIncome.toStringAsFixed(0)} ₺
• Aylık gider: ${ctx.monthlyExpenses.toStringAsFixed(0)} ₺
• Net nakit: ${ctx.netCash.toStringAsFixed(0)} ₺
• Portföy: ${ctx.portfolioSummary}
• Son işlemler: ${ctx.transactionsSummary}''';

    final modeNote = switch (mode) {
      'budget_audit' =>
        '\n\n**Mod: Bütçe Denetimi** — Harcama alışkanlıklarını analiz et, '
        'tasarruf ve optimizasyon önerileri ver. Spesifik rakamlar ve yüzdeler kullan.',
      'portfolio_advisor' =>
        '\n\n**Mod: Yatırım Tavsiyesi** — Portföy kompozisyonunu değerlendir, '
        'Türk piyasası (BIST, TEFAS, döviz, altın) odaklı somut tavsiyeler ver.',
      'goal_tracker' when ctx.goalTitle != null =>
        '\n\n**Mod: Hedef Takibi** — Hedef: ${ctx.goalTitle} | '
        'İlerleme: %${ctx.goalProgress?.toStringAsFixed(0)} | '
        'Son tarih: ${ctx.goalDeadline ?? "belirtilmemiş"}\n'
        'Hedefe ulaşma planı oluştur, gerçekçi tavsiyeler ver.',
      'goal_tracker' =>
        '\n\n**Mod: Hedef Takibi** — Kullanıcının finansal hedeflerine yönelik '
        'analiz ve plan yap.',
      _ =>
        '\n\n**Mod: Serbest Sohbet** — Finans, ekonomi, yatırım konularında '
        'Türkçe uzman tavsiyesi ver.',
    };

    return '$base$modeNote\n\nYanıtlarını **maksimum 350 kelime** ile sınırla.';
  }
}
