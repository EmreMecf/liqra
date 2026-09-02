import 'money_flow.dart';

/// İşlem kategorileri
///
/// ÖNEMLİ: Firestore'a **her zaman** [TransactionCategoryExt.slug] yazılır
/// (`market`, `yemeicme`, `yatirim` …). Türkçe etiketler yalnızca UI'da
/// gösterilir. Okuma tarafı [TransactionCategoryX.parse] ile hem slug'ı hem de
/// eski kayıtlardaki Türkçe etiketleri kabul eder.
enum TransactionCategory {
  market,
  yemeicme,
  eglence,
  fatura,
  ulasim,
  saglik,
  giyim,
  egitim,
  teknoloji,
  yatirim,
  diger,
  gelir,
}

extension TransactionCategoryExt on TransactionCategory {
  /// Firestore'a yazılan kanonik anahtar (ASCII, küçük harf)
  String get slug => name;

  String get label {
    switch (this) {
      case TransactionCategory.market:    return 'Market';
      case TransactionCategory.yemeicme:  return 'Yeme-İçme';
      case TransactionCategory.eglence:   return 'Eğlence';
      case TransactionCategory.fatura:    return 'Fatura';
      case TransactionCategory.ulasim:    return 'Ulaşım';
      case TransactionCategory.saglik:    return 'Sağlık';
      case TransactionCategory.giyim:     return 'Giyim';
      case TransactionCategory.egitim:    return 'Eğitim';
      case TransactionCategory.teknoloji: return 'Teknoloji';
      case TransactionCategory.yatirim:   return 'Yatırım';
      case TransactionCategory.gelir:     return 'Gelir';
      case TransactionCategory.diger:     return 'Diğer';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.market:    return '🛒';
      case TransactionCategory.yemeicme:  return '🍽️';
      case TransactionCategory.eglence:   return '🎬';
      case TransactionCategory.fatura:    return '📄';
      case TransactionCategory.ulasim:    return '🚌';
      case TransactionCategory.saglik:    return '💊';
      case TransactionCategory.giyim:     return '👕';
      case TransactionCategory.egitim:    return '📚';
      case TransactionCategory.teknoloji: return '💻';
      case TransactionCategory.yatirim:   return '📈';
      case TransactionCategory.gelir:     return '💰';
      case TransactionCategory.diger:     return '📦';
    }
  }
}

/// Kategori ayrıştırma — tek doğruluk kaynağı.
///
/// Hem yeni slug'ları (`yemeicme`) hem de geçmişte yazılmış Türkçe etiketleri
/// (`Yeme-İçme`, `Alışveriş`) ve OCR/muhasebe ekranlarındaki varyantları kabul eder.
/// Böylece mevcut Firestore verisi migration olmadan doğru okunur.
extension TransactionCategoryX on TransactionCategory {
  static TransactionCategory parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return TransactionCategory.diger;

    // Türkçe'ye özgü büyük/küçük harf tuzaklarını da kapsayan normalizasyon
    final n = raw
        .trim()
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('̇', '') // birleşen nokta (i̇)
        .replaceAll(RegExp(r'[\s\-_]'), '');

    switch (n) {
      case 'market':
      case 'alisveris':
      case 'grocery':
        return TransactionCategory.market;
      case 'yemeicme':
      case 'yemek':
        return TransactionCategory.yemeicme;
      case 'eglence':
        return TransactionCategory.eglence;
      case 'fatura':
      case 'kredi':          // kredi taksidi — sabit ödeme olarak faturaya girer
      case 'abonelik':
        return TransactionCategory.fatura;
      case 'ulasim':
        return TransactionCategory.ulasim;
      case 'saglik':
        return TransactionCategory.saglik;
      case 'giyim':
        return TransactionCategory.giyim;
      case 'egitim':
        return TransactionCategory.egitim;
      case 'teknoloji':
        return TransactionCategory.teknoloji;
      case 'yatirim':
      case 'portfoy':
        return TransactionCategory.yatirim;
      case 'gelir':
      case 'maas':
      case 'income':
        return TransactionCategory.gelir;
      default:
        return TransactionCategory.diger;
    }
  }

  /// Ham kategori değerini kanonik slug'a çevirir (raporlama/karşılaştırma için)
  static String slugOf(String? raw) => parse(raw).slug;
}

/// Finansal işlem modeli
class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionCategory category;
  /// income | expense
  final String type;
  /// manual | ocr | recurring
  final String source;
  final DateTime date;
  final String? note;

  /// Para hareketi türü — gider/gelir/nakit etkisinin TEK kaynağı.
  final MoneyFlow flow;

  /// Hareketin bağlı olduğu hesap (banka/kart/yatırım). Eski kayıtlarda null.
  final String? accountId;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.source,
    required this.date,
    this.note,
    this.flow = MoneyFlow.expense,
    this.accountId,
  });

  // Gelir/gider artık ham `type` string'ine değil akış tipine bakar.
  bool get isIncome  => flow.countsAsIncome;
  bool get isExpense => flow.countsAsExpense;

  /// Nakit üzerindeki işaretli etki (kart harcaması nakdi etkilemez)
  double get cashEffect => amount * flow.cashDirection;

  TransactionModel copyWith({
    double? amount,
    TransactionCategory? category,
    String? type,
    DateTime? date,
    String? note,
    MoneyFlow? flow,
    String? accountId,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      source: source,
      date: date ?? this.date,
      note: note ?? this.note,
      flow: flow ?? this.flow,
      accountId: accountId ?? this.accountId,
    );
  }
}
