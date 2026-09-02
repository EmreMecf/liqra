/// Para hareketinin türü — uygulamanın muhasebe çekirdeği.
///
/// `type: income | expense` ikilisi yetersizdi: bir para hareketinin **nakde**,
/// **gidere**, **servete** ve **borca** etkisi birbirinden farklıdır. Örnekler:
///
///  • Midas'a 10.000 ₺ göndermek → nakit azalır ama GİDER DEĞİLDİR
///    (servet kaybolmadı, biçim değiştirdi). Eskiden gider sayılıyordu ve
///    portföye varlık eklenince ikinci kez daha sayılıyordu.
///  • Kredi kartı ekstresi ödemek → nakit azalır ama GİDER DEĞİLDİR
///    (gider zaten satın alma anında oluştu). Aksi hâlde çift sayılır.
///
/// **Muhasebe esası: TAHAKKUK.** Kredi kartı harcaması, ödeme anında değil
/// satın alma anında gider yazılır — böylece "bu ay ne kadar harcadım"
/// sorusu gerçeği gösterir.
enum MoneyFlow {
  /// Gerçek gelir — nakit girer, servet artar. (Maaş, kira geliri)
  income,

  /// Gerçek gider — nakit çıkar, servet azalır. (Nakit/banka kartıyla market)
  expense,

  /// Kredi kartı harcaması — nakit çıkmaz, borç artar, GİDER sayılır (tahakkuk).
  cardExpense,

  /// Kredi kartı ekstre ödemesi — nakit çıkar, borç azalır, gider DEĞİL.
  cardPayment,

  /// Hesaplar arası aktarım — net etkisi yok.
  transfer,

  /// Yatırım alımı — nakit çıkar, servet biçim değiştirir, gider DEĞİL.
  investment,

  /// Kredi taksidi — nakit çıkar ve bütçe gerçekliği açısından gider sayılır
  /// (kredinin kullanıldığı an gelir olarak kaydedilmediği için).
  loanPayment,
}

extension MoneyFlowX on MoneyFlow {
  /// Firestore'a yazılan kanonik anahtar
  String get slug => name;

  /// Kullanıcıya gösterilen etiket
  String get label => switch (this) {
        MoneyFlow.income      => 'Gelir',
        MoneyFlow.expense     => 'Gider',
        MoneyFlow.cardExpense => 'Kart Harcaması',
        MoneyFlow.cardPayment => 'Kart Ödemesi',
        MoneyFlow.transfer    => 'Transfer',
        MoneyFlow.investment  => 'Yatırım',
        MoneyFlow.loanPayment => 'Kredi Taksidi',
      };

  /// Aylık **gider** toplamına dahil mi?
  ///
  /// Yatırım, transfer ve kart ödemesi gider DEĞİLDİR — bunlar servet
  /// transferi ya da borç kapatmadır.
  bool get countsAsExpense => switch (this) {
        MoneyFlow.expense     => true,
        MoneyFlow.cardExpense => true,   // tahakkuk esası
        MoneyFlow.loanPayment => true,
        MoneyFlow.income      => false,
        MoneyFlow.cardPayment => false,
        MoneyFlow.transfer    => false,
        MoneyFlow.investment  => false,
      };

  /// Aylık **gelir** toplamına dahil mi?
  bool get countsAsIncome => this == MoneyFlow.income;

  /// Nakit üzerindeki etkisi: -1 çıkış, +1 giriş, 0 nötr.
  ///
  /// Kart harcaması nakdi ETKİLEMEZ (borç doğar); kart ödemesi nakdi azaltır.
  int get cashDirection => switch (this) {
        MoneyFlow.income      => 1,
        MoneyFlow.expense     => -1,
        MoneyFlow.cardPayment => -1,
        MoneyFlow.investment  => -1,
        MoneyFlow.loanPayment => -1,
        MoneyFlow.cardExpense => 0,
        MoneyFlow.transfer    => 0,
      };

  /// Kategori dağılımı / bütçe grafiklerinde gösterilmeli mi?
  /// Yalnızca gerçek tüketim kalemleri gösterilir.
  bool get showInCategoryBreakdown => countsAsExpense;
}

/// Akış tipi ayrıştırma — tek doğruluk kaynağı.
///
/// Eski kayıtlarda `flow` alanı YOKTUR; bu durumda `type` + `category`
/// alanlarından güvenle türetilir, migration gerekmez.
class MoneyFlowParser {
  const MoneyFlowParser._();

  /// [rawFlow] Firestore'daki `flow` alanı (yoksa null)
  /// [rawType] eski `type` alanı: income|expense|gelir|gider|creditPayment|transfer
  /// [categorySlug] kategori slug'ı — eski yatırım kayıtlarını yakalamak için
  static MoneyFlow parse({
    String? rawFlow,
    String? rawType,
    String? categorySlug,
  }) {
    // 1) Açıkça yazılmışsa onu kullan
    final f = rawFlow?.trim();
    if (f != null && f.isNotEmpty) {
      for (final v in MoneyFlow.values) {
        if (v.name == f) return v;
      }
    }

    // 2) Eski kayıt — type'tan türet
    final t = (rawType ?? '').trim();
    switch (t) {
      case 'income':
      case 'gelir':
        return MoneyFlow.income;
      case 'creditPayment':
        return MoneyFlow.cardPayment;
      case 'transfer':
        return MoneyFlow.transfer;
    }

    // 3) Gider ama kategori 'yatirim' ise aslında yatırımdır.
    //    Eski sürüm portföye varlık eklerken bunu gider olarak yazıyordu.
    if ((categorySlug ?? '').trim() == 'yatirim') return MoneyFlow.investment;

    return MoneyFlow.expense;
  }
}
