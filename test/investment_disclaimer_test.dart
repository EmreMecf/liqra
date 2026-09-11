import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_context.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_prompts.dart';
import 'package:muhasebe/presentation/widgets/investment_disclaimer.dart';

/// Yatırım uyarısı — yasal ve mağaza incelemesi gereği.
///
/// Türkiye'de kişiye özel yatırım danışmanlığı SPK lisansı gerektirir.
/// Uyarı eskiden yalnızca gizlilik politikasında duruyordu; kullanıcı analizi
/// okuduğu ekranda hiç görmüyordu. Bu testler hem ekrandaki metnin hem de
/// modele verilen kuralın bir düzenlemede sessizce kaybolmamasını sağlar.
void main() {
  group('Yatırım uyarısı', () {
    test('metin tavsiye olmadığını açıkça söylüyor', () {
      expect(InvestmentDisclaimer.text, contains('yatırım tavsiyesi değildir'));
      expect(InvestmentDisclaimer.text, contains('bilgilendirme amaçlıdır'));
    });

    test('hisse analizi prompt\'u kesin al/sat talimatını yasaklıyor', () {
      final prompt = AssistantPrompts.stockAnalysis(
        symbol: 'THYAO',
        ctx: AssistantContext(now: DateTime(2026, 9, 11)),
      );
      expect(prompt, contains('Karar kullanıcınındır'));
      expect(prompt, contains('"Al", "sat", "tut"'));
    });
  });
}
