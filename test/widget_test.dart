import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/core/utils/formatters.dart';
import 'package:muhasebe/core/utils/result.dart';
import 'package:muhasebe/core/services/auth_service.dart';
import 'package:muhasebe/data/models/transaction_model.dart';

void main() {
  // ── Formatters ─────────────────────────────────────────────────────────────

  group('Formatters.currency', () {
    test('binlik ayraç nokta ile formatlar', () {
      expect(Formatters.currency(1000), '1.000 TL');
      expect(Formatters.currency(289847), '289.847 TL');
      expect(Formatters.currency(1000000), '1.000.000 TL');
    });

    test('negatif değerleri doğru formatlar', () {
      expect(Formatters.currency(-500), '-500 TL');
      expect(Formatters.currency(-12500), '-12.500 TL');
    });

    test('showSymbol false ise TL eklenmez', () {
      expect(Formatters.currency(1000, showSymbol: false), '1.000');
    });

    test('sıfırı doğru formatlar', () {
      expect(Formatters.currency(0), '0 TL');
    });
  });

  group('Formatters.currencyDecimal', () {
    test('ondalık kısmı virgülle gösterir', () {
      expect(Formatters.currencyDecimal(1234.5), '1.234,50 TL');
      expect(Formatters.currencyDecimal(0.99), '0,99 TL');
    });
  });

  group('Formatters.percent', () {
    test('pozitif değerlere + işareti ekler', () {
      expect(Formatters.percent(12.4), '+12,4%');
      expect(Formatters.percent(3.0), '+3,0%');
    });

    test('negatif değerleri doğru formatlar', () {
      expect(Formatters.percent(-3.2), '-3,2%');
    });

    // Not: Bu test eskiden '+16%' bekliyordu; aynı dosyadaki
    // "pozitif değerlere + işareti ekler" testi ise percent(12.4) için
    // '+12,4%' bekliyordu — ikisi aynı anda doğru olamazdı.
    // Formatters.percent dokümantasyonu ve DeltaChip gösterimi tek ondalıklı
    // olduğu için davranış her değerde tek ondalık olarak sabitlendi.
    test('büyük değerlerde de tek ondalık gösterir', () {
      expect(Formatters.percent(15.7), '+15,7%');
      expect(Formatters.percent(120.0), '+120,0%');
    });

    test('negatifte çift eksi yazmaz', () {
      expect(Formatters.percent(-5.0), '-5,0%');
      expect(Formatters.percent(-12.5), '-12,5%');
    });

    test('showSign false ise + eklenmez', () {
      expect(Formatters.percent(5.0, showSign: false), '5,0%');
    });
  });

  group('Formatters.compact', () {
    test('binleri B ile gösterir', () {
      expect(Formatters.compact(1500), '1,5B');
      expect(Formatters.compact(289847), '289,8B');
    });

    test('milyonları M ile gösterir', () {
      expect(Formatters.compact(1200000), '1.2M');
    });

    test('küçük değerleri TL olarak gösterir', () {
      expect(Formatters.compact(500), '500 TL');
    });
  });

  group('Formatters.date', () {
    test('Türkçe kısa ay adı ile formatlar', () {
      expect(Formatters.date(DateTime(2026, 3, 23)), '23 Mar 2026');
      expect(Formatters.date(DateTime(2026, 12, 1)), '1 Ara 2026');
    });
  });

  group('Formatters.monthYear', () {
    test('tam ay adı ve yıl döner', () {
      expect(Formatters.monthYear(DateTime(2026, 1)), 'Ocak 2026');
      expect(Formatters.monthYear(DateTime(2026, 8)), 'Ağustos 2026');
    });
  });

  // ── Result<T> ──────────────────────────────────────────────────────────────

  group('Result', () {
    test('Success.isSuccess true döner', () {
      final result = Success<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 42);
    });

    test('Failure.isFailure true döner', () {
      final result = Failure<int>(const NetworkFailure('Bağlantı yok'));
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failure.message, 'Bağlantı yok');
    });

    test('when() doğru dala gider', () {
      final success = Success<String>('merhaba');
      final out = success.when(
        success: (d) => 'ok:$d',
        failure: (_) => 'hata',
      );
      expect(out, 'ok:merhaba');

      final failure = Failure<String>(const ServerFailure('500'));
      final out2 = failure.when(
        success: (_) => 'ok',
        failure: (f) => 'hata:${f.message}',
      );
      expect(out2, 'hata:500');
    });

    test('onSuccess sadece Success için çalışır', () {
      int called = 0;
      Success<int>(1).onSuccess((_) => called++);
      Failure<int>(const CacheFailure('x')).onSuccess((_) => called++);
      expect(called, 1);
    });

    test('onFailure sadece Failure için çalışır', () {
      int called = 0;
      Failure<int>(const UnknownFailure('?')).onFailure((_) => called++);
      Success<int>(99).onFailure((_) => called++);
      expect(called, 1);
    });
  });

  // ── AppFailure subtypes ────────────────────────────────────────────────────

  group('AppFailure', () {
    test('NetworkFailure statusCode alanını taşır', () {
      const f = NetworkFailure('Zaman aşımı', statusCode: 408);
      expect(f.statusCode, 408);
      expect(f.message, 'Zaman aşımı');
    });

    test('tüm Failure tipleri mesaj döner', () {
      const failures = <AppFailure>[
        NetworkFailure('net'),
        ServerFailure('srv'),
        CacheFailure('cache'),
        UnknownFailure('unknown'),
      ];
      for (final f in failures) {
        expect(f.message, isNotEmpty);
      }
    });
  });

  // ── AuthResult ─────────────────────────────────────────────────────────────

  group('AuthResult', () {
    test('success() başarı döner, errorMessage null', () {
      final r = AuthResult.success();
      expect(r.success, isTrue);
      expect(r.errorMessage, isNull);
    });

    test('error() başarısızlık ve mesaj döner', () {
      final r = AuthResult.error('Şifre hatalı.');
      expect(r.success, isFalse);
      expect(r.errorMessage, 'Şifre hatalı.');
    });
  });

  // ── Formatters.frequency ──────────────────────────────────────────────────

  group('Formatters.frequency', () {
    test('frekans etiketlerini Türkçeye çevirir', () {
      expect(Formatters.frequency('monthly'), 'Aylık');
      expect(Formatters.frequency('annual'), 'Yıllık');
      expect(Formatters.frequency('weekly'), 'Haftalık');
      expect(Formatters.frequency('other'), 'other');
    });
  });

  // ── TransactionCategory ayrıştırma ─────────────────────────────────────────
  //
  // Firestore'a slug yazılır; ancak eski kayıtlarda Türkçe etiketler var.
  // parse() ikisini de tanımalı — aksi halde "Yatırım" harcaması gider olarak
  // sayılır ve net nakit yanlış hesaplanır.

  group('TransactionCategoryX.parse', () {
    test('slug değerlerini tanır', () {
      expect(TransactionCategoryX.parse('market'), TransactionCategory.market);
      expect(TransactionCategoryX.parse('yemeicme'), TransactionCategory.yemeicme);
      expect(TransactionCategoryX.parse('yatirim'), TransactionCategory.yatirim);
    });

    test('eski Türkçe etiketleri tanır', () {
      expect(TransactionCategoryX.parse('Yatırım'), TransactionCategory.yatirim);
      expect(TransactionCategoryX.parse('Yeme-İçme'), TransactionCategory.yemeicme);
      expect(TransactionCategoryX.parse('Ulaşım'), TransactionCategory.ulasim);
      expect(TransactionCategoryX.parse('Sağlık'), TransactionCategory.saglik);
      expect(TransactionCategoryX.parse('Eğitim'), TransactionCategory.egitim);
    });

    test('OCR ve muhasebe varyantlarını eşler', () {
      expect(TransactionCategoryX.parse('Alışveriş'), TransactionCategory.market);
      expect(TransactionCategoryX.parse('Kredi'), TransactionCategory.fatura);
      expect(TransactionCategoryX.parse('maas'), TransactionCategory.gelir);
    });

    test('bilinmeyen ve boş değerler diger olur', () {
      expect(TransactionCategoryX.parse('zzz'), TransactionCategory.diger);
      expect(TransactionCategoryX.parse(''), TransactionCategory.diger);
      expect(TransactionCategoryX.parse(null), TransactionCategory.diger);
    });

    test('slugOf her zaman kanonik slug döner', () {
      expect(TransactionCategoryX.slugOf('Yatırım'), 'yatirim');
      expect(TransactionCategoryX.slugOf('yatirim'), 'yatirim');
      expect(TransactionCategoryX.slugOf('Market'), 'market');
    });

    test('slug ile enum adı aynıdır', () {
      for (final c in TransactionCategory.values) {
        expect(c.slug, c.name);
        expect(TransactionCategoryX.parse(c.slug), c);
      }
    });
  });
}
