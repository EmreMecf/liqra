/// İşlem kategorileri
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
  diger,
  gelir,
}

extension TransactionCategoryExt on TransactionCategory {
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
      case TransactionCategory.gelir:     return '💰';
      case TransactionCategory.diger:     return '📦';
    }
  }
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

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.source,
    required this.date,
    this.note,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  TransactionModel copyWith({
    double? amount,
    TransactionCategory? category,
    String? type,
    DateTime? date,
    String? note,
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
    );
  }
}
