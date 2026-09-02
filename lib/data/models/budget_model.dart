import 'transaction_model.dart';

/// Kategori bazlı aylık harcama limitleri.
///
/// ── Neden tek doküman ───────────────────────────────────────────────────────
/// Limitler `users/{uid}/settings/budgets` altında **tek bir dokümanda** map
/// olarak tutulur. Kategori sayısı sabit ve küçük (12); alt koleksiyon yapmak
/// her açılışta 12 okuma demek olurdu, bu şekilde bir okuma yeterli.
///
/// Anahtar daima kanonik slug'dır (`market`, `yemeicme`) — Türkçe etiket
/// **yazılmaz**, aksi hâlde kategori sözleşmesi bozulur.
class BudgetModel {
  /// Kategori slug → aylık limit (₺). Limiti olmayan kategori haritada yoktur.
  final Map<String, double> limits;

  const BudgetModel({this.limits = const {}});

  static const empty = BudgetModel();

  bool get isEmpty => limits.isEmpty;
  bool get isNotEmpty => limits.isNotEmpty;

  /// Bir kategorinin limiti (tanımlı değilse null).
  double? limitFor(TransactionCategory category) => limits[category.slug];

  bool hasLimit(TransactionCategory category) =>
      (limits[category.slug] ?? 0) > 0;

  /// Limiti olan kategorilerin toplamı — "aylık bütçe" büyüklüğü.
  double get totalLimit => limits.values.fold(0.0, (a, b) => a + b);

  BudgetModel withLimit(TransactionCategory category, double? limit) {
    final next = Map<String, double>.from(limits);
    if (limit == null || limit <= 0) {
      next.remove(category.slug);
    } else {
      next[category.slug] = limit;
    }
    return BudgetModel(limits: next);
  }

  Map<String, dynamic> toMap() => {'limits': limits};

  factory BudgetModel.fromMap(Map<String, dynamic>? data) {
    final raw = data?['limits'];
    if (raw is! Map) return empty;

    final parsed = <String, double>{};
    for (final entry in raw.entries) {
      final amount = (entry.value as num?)?.toDouble() ?? 0;
      if (amount <= 0) continue;
      // Eski kayıtlarda Türkçe etiket bulunabilir; kanonik slug'a çevir.
      parsed[TransactionCategoryX.slugOf(entry.key.toString())] = amount;
    }
    return BudgetModel(limits: parsed);
  }
}

/// Bir kategorinin bu ayki bütçe durumu.
class BudgetStatus {
  final TransactionCategory category;
  final double limit;
  final double spent;

  const BudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;

  /// Kullanım oranı. Gösterge çubuğu için 0–1 arasına kırpılır; aşımı görmek
  /// için [isOver] veya [rawRatio] kullanın.
  double get ratio => rawRatio.clamp(0.0, 1.0);
  double get rawRatio => limit > 0 ? spent / limit : 0;

  bool get isOver => spent > limit;

  /// Limite yaklaşıldı mı? (%80 ve üzeri, henüz aşılmamış)
  bool get isNear => !isOver && rawRatio >= 0.80;

  /// Aşım tutarı (aşılmadıysa 0).
  double get overspend => isOver ? spent - limit : 0;
}
