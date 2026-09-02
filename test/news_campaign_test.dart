import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/core/utils/category_slug.dart';
import 'package:muhasebe/data/models/transaction_model.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_context.dart';
import 'package:muhasebe/features/ai_assistant/domain/campaign_matcher.dart';
import 'package:muhasebe/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:muhasebe/features/news/domain/entities/news_entity.dart';

/// Haber ve kampanya hattının denetiminde bulunan hataları kayda geçirir.
void main() {
  group('Kategori slug uyumu', () {
    // Cloud Functions Firestore'a ASCII slug yazar; istemci switch'i Türkçe
    // karakterli hâli bekliyordu ve HİÇBİRİ eşleşmiyordu.
    test('Cloud Functions ASCII slug yazsa da kampanya kategorisi tanınır', () {
      expect(CampaignCategory.fromString('alisveris'),
          CampaignCategory.alisveris);
      expect(CampaignCategory.fromString('akaryakit'),
          CampaignCategory.akaryakit);
    });

    test('eski Türkçe karakterli kayıtlar da tanınır — migration gerekmez', () {
      expect(CampaignCategory.fromString('alışveriş'),
          CampaignCategory.alisveris);
      expect(CampaignCategory.fromString('AKARYAKIT'),
          CampaignCategory.akaryakit);
    });

    test('bilinmeyen ve boş değerler diger olur', () {
      expect(CampaignCategory.fromString(null), CampaignCategory.diger);
      expect(CampaignCategory.fromString(''), CampaignCategory.diger);
      expect(CampaignCategory.fromString('zzz'), CampaignCategory.diger);
    });

    test('haber kategorisi her iki yazımı da tanır', () {
      expect(NewsCategory.fromString('doviz'), NewsCategory.doviz);
      expect(NewsCategory.fromString('döviz'), NewsCategory.doviz);
      expect(NewsCategory.fromString('sirket'), NewsCategory.sirket);
      expect(NewsCategory.fromString('bilinmeyen'), NewsCategory.genel);
    });

    test('normalizeCategorySlug Türkçe karakterleri düşürür', () {
      expect(normalizeCategorySlug('Alışveriş'), 'alisveris');
      expect(normalizeCategorySlug('Döviz'), 'doviz');
      expect(normalizeCategorySlug('Şirket-Haber'), 'sirkethaber');
    });

    test('enum adı ile slug aynıdır — Firestore filtresi çalışır', () {
      for (final c in CampaignCategory.values) {
        expect(CampaignCategory.fromString(c.name), c,
            reason: '${c.name} kendi adından geri okunabilmeli');
      }
      for (final n in NewsCategory.values) {
        expect(NewsCategory.fromString(n.name), n,
            reason: '${n.name} kendi adından geri okunabilmeli');
      }
    });
  });

  group('Kampanya harita tutarlılığı', () {
    // Harita 'Alışveriş' diye bir kategoriye bakıyordu ama uygulamada böyle
    // bir harcama kategorisi YOK — alışveriş kampanyaları hiç eşleşmiyordu.
    test('haritadaki her etiket gerçek bir harcama kategorisidir', () {
      final real =
          TransactionCategory.values.map((c) => c.label).toSet();

      for (final entry in CampaignMatcher.categoryMap.entries) {
        for (final label in entry.value) {
          expect(real, contains(label),
              reason: '"${entry.key}" → "$label" diye bir kategori yok');
        }
      }
    });

    test('her kampanya kategorisi haritada karşılık bulur', () {
      for (final c in CampaignCategory.values) {
        if (c == CampaignCategory.diger) continue;
        expect(CampaignMatcher.categoryMap.keys, contains(c.name));
      }
    });
  });

  group('Kampanya eşleştirme', () {
    AssistantContext ctx({
      Map<String, double> spend = const {},
      List<CampaignOffer> campaigns = const [],
    }) =>
        AssistantContext(
          now: DateTime(2026, 3, 15),
          spending: SpendingSnapshot(
            income: 40000,
            expenses: 25000,
            byCategory: spend,
          ),
          campaigns: campaigns,
        );

    const shopping = CampaignOffer(
      id: 'c1',
      bank: 'Garanti BBVA',
      title: "Trendyol'da 200 TL Bonus",
      description: '',
      category: 'alisveris',
    );

    test('alışveriş kampanyası giyim/teknoloji harcamasıyla eşleşir', () {
      final matches = CampaignMatcher.match(
        ctx(
          spend: {'Giyim': 3000, 'Teknoloji': 2500},
          campaigns: [shopping],
        ),
      );
      expect(matches, hasLength(1));
      expect(matches.first.monthlySpend, 5500);
    });

    test('aynı kategori iki kez sayılmaz', () {
      // 'seyahat' ve 'akaryakit' ikisi de Ulaşım'a bakar; tek bir kampanya
      // içinde Ulaşım iki kez toplanmamalı.
      final matches = CampaignMatcher.match(
        ctx(
          spend: {'Ulaşım': 4000},
          campaigns: [
            const CampaignOffer(
              id: 'c2',
              bank: 'Akbank',
              title: 'Uçuşta indirim',
              description: '',
              category: 'seyahat',
            ),
          ],
        ),
      );
      expect(matches.first.monthlySpend, 4000);
    });

    test('kısmi isim benzerliği yanlış kategoriyi eşleştirmez', () {
      // 'Market' ile 'Marketing' gibi kısmi eşleşmeler tutar şişirirdi.
      final matches = CampaignMatcher.match(
        ctx(
          spend: {'Sağlık': 9000},
          campaigns: [shopping],
        ),
      );
      expect(matches, isEmpty);
    });
  });

  group('Örnek kampanyalar bildirilmez', () {
    AssistantContext ctxWith(List<CampaignOffer> campaigns) => AssistantContext(
          now: DateTime(2026, 3, 15),
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 25000,
            byCategory: {'Market': 8000},
          ),
          campaigns: campaigns,
        );

    const sample = CampaignOffer(
      id: 's1',
      bank: 'Garanti BBVA',
      title: 'Markette %15 Bonus',
      description: '',
      category: 'market',
      isSample: true,
    );
    const real = CampaignOffer(
      id: 'r1',
      bank: 'Garanti BBVA',
      title: 'Markette %15 Bonus',
      description: '',
      category: 'market',
    );

    test('uydurma kampanya telefona bildirim olarak GİTMEZ', () {
      // Seed veriler gerçek banka teklifi değil. Bunları bildirime çevirmek
      // kullanıcıyı olmayan bir kampanyaya göre harcamaya yöneltir.
      final matches = CampaignMatcher.match(
        ctxWith([sample]),
        userBanks: {'Garanti BBVA'},
      );
      expect(matches, hasLength(1), reason: 'uygulama içinde görünmeye devam');
      expect(CampaignMatcher.toInsights(matches), isEmpty);
    });

    test('gerçek kampanya bildirilir', () {
      final matches = CampaignMatcher.match(
        ctxWith([real]),
        userBanks: {'Garanti BBVA'},
      );
      expect(CampaignMatcher.toInsights(matches), hasLength(1));
    });

    test('prompt bloğunda örnek kampanya işaretlenir', () {
      final block = ctxWith([sample]).toPromptBlock();
      expect(block, contains('ÖRNEK İÇERİK'));
      expect(block, contains('doğrulaman gerekir'));
    });

    test('gerçek kampanyada uyarı satırı çıkmaz', () {
      expect(ctxWith([real]).toPromptBlock(), isNot(contains('ÖRNEK İÇERİK')));
    });
  });
}
