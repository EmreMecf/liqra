/// Kredi kartı ekstre döngüsü — kesim ve son ödeme tarihlerinin TEK kaynağı.
///
/// ── Neden ayrı bir sınıf ───────────────────────────────────────────────────
/// Tarih hesabı eskiden entity getter'ları içinde satır içi yapılıyordu ve üç
/// ayrı hata barındırıyordu:
///
///  1. `DateTime(y, m, 31)` şubatta hata vermez, sessizce **3 Mart**'a taşar.
///  2. Gece yarısı kurulan `due` ile saat taşıyan `now` karşılaştırılınca,
///     ödemenin son günü "geçmiş" sayılıp tarih bir ay ileri atlıyordu.
///  3. Son ödeme tarihi tanım gereği hep gelecekte olduğu için `isOverdue`
///     hiçbir zaman doğru olamıyordu — gecikme tespit edilemiyordu.
///
/// Bu sınıf üçünü de kaynağında çözer: tüm tarihler **gün başına normalize**
/// edilir, ayın gün sayısını aşan gün numaraları ayın **son gününe sabitlenir**
/// ve "şu an ödenmesi gereken ekstre" ile "bir sonraki ödeme" ayrı ayrı
/// modellenir.
class BillingCycle {
  /// Ekstre kesim günü (1–31). Ayın gün sayısını aşarsa son güne sabitlenir.
  final int closingDay;

  /// Son ödeme günü (1–31). Ayın gün sayısını aşarsa son güne sabitlenir.
  final int dueDay;

  /// Referans gün — daima gün başına normalize edilmiştir (saat 00:00).
  final DateTime today;

  BillingCycle({
    required int closingDay,
    required int dueDay,
    DateTime? now,
  })  : closingDay = closingDay.clamp(1, 31),
        dueDay = dueDay.clamp(1, 31),
        today = dateOnly(now ?? DateTime.now());

  // ── Yardımcılar ────────────────────────────────────────────────────────────

  /// Saat/dakika bilgisini atar — tarih karşılaştırmaları gün bazında yapılır.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Verilen ayın gün sayısı. `DateTime(y, m + 1, 0)` bir önceki ayın son
  /// gününü verir ve artık yılı da doğru hesaplar.
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Ayın gün sayısını aşan gün numarasını ayın SON gününe sabitler.
  /// `dayInMonth(2026, 2, 31)` → 28 Şubat 2026 (3 Mart DEĞİL).
  static DateTime dayInMonth(int year, int month, int day) {
    // Normalize: month 0 veya 13 gibi değerler yıl taşmasıyla düzeltilir.
    final normalized = DateTime(year, month, 1);
    final last = daysInMonth(normalized.year, normalized.month);
    return DateTime(normalized.year, normalized.month, day.clamp(1, last));
  }

  DateTime _closingIn(int year, int month) => dayInMonth(year, month, closingDay);

  /// Bir kesim tarihine ait ekstrenin son ödeme tarihi.
  ///
  /// Son ödeme günü kesim gününden büyükse ödeme AYNI ay içindedir
  /// (kesim 1'i → ödeme 10'u); değilse bir sonraki aya sarkar
  /// (kesim 15'i → ödeme 5'i).
  DateTime dueDateFor(DateTime closingDate) {
    final sameMonth = dueDay > closingDay;
    return dayInMonth(
      closingDate.year,
      closingDate.month + (sameMonth ? 0 : 1),
      dueDay,
    );
  }

  // ── Kesim tarihleri ────────────────────────────────────────────────────────

  /// Bugün itibarıyla KAPANMIŞ en son ekstrenin kesim tarihi.
  DateTime get lastClosingDate {
    final thisMonth = _closingIn(today.year, today.month);
    if (!thisMonth.isAfter(today)) return thisMonth;
    return _closingIn(today.year, today.month - 1);
  }

  /// Henüz kapanmamış (açık) ekstrenin kesim tarihi.
  DateTime get nextClosingDate {
    final thisMonth = _closingIn(today.year, today.month);
    if (thisMonth.isAfter(today)) return thisMonth;
    return _closingIn(today.year, today.month + 1);
  }

  /// Bir harcamanın hangi ekstrede faturalanacağını söyler —
  /// harcama tarihinde veya sonrasındaki ilk kesim tarihi.
  DateTime closingDateForPurchase(DateTime purchaseDate) {
    final d = dateOnly(purchaseDate);
    final thisMonth = _closingIn(d.year, d.month);
    if (!thisMonth.isBefore(d)) return thisMonth;
    return _closingIn(d.year, d.month + 1);
  }

  // ── Ödeme tarihleri ────────────────────────────────────────────────────────

  /// Şu an ödenmesi gereken ekstrenin son ödeme tarihi.
  /// Bu tarih GEÇMİŞTE olabilir — gecikme tespiti buna dayanır.
  DateTime get currentDueDate => dueDateFor(lastClosingDate);

  /// Bugün dahil, gelecekteki ilk son ödeme tarihi.
  DateTime get nextDueDate {
    final current = currentDueDate;
    if (!current.isBefore(today)) return current;
    return dueDateFor(nextClosingDate);
  }

  /// Bir sonraki son ödeme tarihine kaç TAM gün kaldığı.
  /// Bugün son gün ise 0 döner (bir ay ileri atlamaz).
  int get daysUntilDue => nextDueDate.difference(today).inDays;

  /// Şu anki ekstrenin son ödeme tarihi geçti mi?
  /// Borç olup olmadığını bilmez — o kontrolü çağıran taraf yapar.
  bool get isPastDue => today.isAfter(currentDueDate);

  /// Son ödeme tarihi kaç gün önce geçti (geçmediyse 0).
  int get daysPastDue =>
      isPastDue ? today.difference(currentDueDate).inDays : 0;
}
