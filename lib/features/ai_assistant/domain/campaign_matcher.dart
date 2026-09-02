import 'assistant_context.dart';
import 'assistant_insight.dart';

/// Bir kampanyanın kullanıcıya neden uygun olduğu.
class CampaignMatch {
  final CampaignOffer offer;

  /// 0–100 arası uygunluk puanı.
  final int score;

  /// Kullanıcıya gösterilecek gerekçe — "neden bu kampanya".
  final String reason;

  /// Kullanıcının bu kategoride son bir ayda harcadığı tutar.
  final double monthlySpend;

  /// Kampanya bankası kullanıcının kartlarından birine mi ait?
  final bool hasBankCard;

  const CampaignMatch({
    required this.offer,
    required this.score,
    required this.reason,
    required this.monthlySpend,
    required this.hasBankCard,
  });
}

/// Kullanıcının harcama alışkanlığına göre kampanyaları sıralar.
///
/// ── Neden kural, AI değil ───────────────────────────────────────────────────
/// "Bu ay markete 4.200 ₺ harcadın, Garanti'nin market kampanyası var ve
/// Garanti kartın zaten var" bir eşleştirme problemidir, yorum problemi değil.
/// Kural motoru bunu anında ve ücretsiz çözer; model yalnızca metni
/// güzelleştirmek gerekirse devreye girer.
class CampaignMatcher {
  const CampaignMatcher._();

  /// Kampanya kategorisi → harcama kategorisi etiketleri.
  ///
  /// Değerler `TransactionCategory.label` ile birebir aynı olmalıdır;
  /// `campaign_matcher_test.dart` bunu doğrular. Eskiden burada
  /// **'Alışveriş' diye bir kategori vardı ama uygulamada böyle bir kategori
  /// yok** — alışveriş kampanyaları hiçbir harcamayla eşleşemiyordu.
  static const _categoryMap = <String, List<String>>{
    'yemek':     ['Yeme-İçme'],
    'market':    ['Market'],
    'akaryakit': ['Ulaşım'],
    'seyahat':   ['Ulaşım'],
    'alisveris': ['Giyim', 'Teknoloji'],
    'fatura':    ['Fatura'],
  };

  /// Test edilebilirlik için açık — haritanın uygulamadaki kategorilerle
  /// uyumlu kaldığını doğrulamak için kullanılır.
  static Map<String, List<String>> get categoryMap => _categoryMap;

  /// Bildirim göndermeye değer minimum puan.
  static const notifyThreshold = 60;

  /// Kampanyaları puanlayıp sıralar. Puanı 0 olanlar elenir.
  ///
  /// [userBanks] kullanıcının hesap/kartlarının banka adları (görünen ad).
  static List<CampaignMatch> match(
    AssistantContext ctx, {
    Set<String> userBanks = const {},
  }) {
    final spend = ctx.spending.byCategory;
    final matches = <CampaignMatch>[];

    for (final offer in ctx.campaigns) {
      final labels = _categoryMap[offer.category] ?? const [];
      final monthlySpend = _spendForLabels(spend, labels);

      final hasBankCard = userBanks.any(
        (b) => _normalize(b) == _normalize(offer.bank),
      );

      var score = 0;
      final reasons = <String>[];

      // Harcama miktarı — asıl sinyal
      if (monthlySpend >= 5000) {
        score += 50;
        reasons.add('bu ay ${_tl(monthlySpend)} harcadın');
      } else if (monthlySpend >= 2000) {
        score += 35;
        reasons.add('bu ay ${_tl(monthlySpend)} harcadın');
      } else if (monthlySpend >= 500) {
        score += 20;
        reasons.add('bu kategoride düzenli harcaman var');
      }

      // Bankası zaten kullanıcıda — kampanyayı hemen kullanabilir
      if (hasBankCard) {
        score += 30;
        reasons.add('${offer.bank} kartın zaten var');
      }

      // Kategori kullanıcının en çok harcadığı ilk üçte mi?
      final top = ctx.spending.sortedCategories.take(3).map((e) => e.key);
      if (labels.any(top.contains)) {
        score += 20;
        reasons.add('en çok harcadığın kategorilerden');
      }

      // Süresi dolmak üzere olan kampanya öne çıkar
      if (_endsSoon(offer.endDate, ctx.now)) {
        score += 10;
        reasons.add('süresi dolmak üzere');
      }

      if (score == 0) continue;

      matches.add(CampaignMatch(
        offer: offer,
        score: score.clamp(0, 100),
        reason: reasons.join(', '),
        monthlySpend: monthlySpend,
        hasBankCard: hasBankCard,
      ));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  /// Bildirime dönüştürülecek kampanyalar.
  ///
  /// **Örnek (seed) kampanyalar bildirilmez.** Bunlar gerçek banka
  /// API'sinden gelmeyen, uydurma içeriklerdir; telefona "Garanti'de %25 bonus
  /// var" diye bildirim göndermek kullanıcıyı olmayan bir kampanyaya göre
  /// harcamaya yöneltir. Uygulama içinde "Örnek" rozetiyle görünmeye devam
  /// ederler.
  static List<AssistantInsight> toInsights(List<CampaignMatch> matches) =>
      matches
          .where((m) => m.score >= notifyThreshold && !m.offer.isSample)
          .take(3)
          .map((m) => AssistantInsight(
                id: 'campaign_${m.offer.id}',
                severity: InsightSeverity.opportunity,
                emoji: '🎁',
                title: '${m.offer.bank}: ${m.offer.title}',
                body: 'Sana uygun çünkü ${m.reason}.',
                action: 'Kampanyayı gör',
                route: '/kesfet',
                notify: true,
              ))
          .toList();

  // ── Yardımcılar ────────────────────────────────────────────────────────────

  /// Verilen etiketlerin toplam harcaması.
  ///
  /// Aynı harcama kategorisi iki etiketle eşleşirse **bir kez** sayılır;
  /// aksi hâlde tutar şişer ve kampanya olduğundan uygun görünür.
  static double _spendForLabels(
      Map<String, double> spend, List<String> labels) {
    final counted = <String>{};
    var total = 0.0;

    for (final label in labels) {
      final target = _normalize(label);
      for (final e in spend.entries) {
        final key = _normalize(e.key);
        if (key != target) continue;
        if (counted.add(e.key)) total += e.value;
      }
    }
    return total;
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Kampanya bitiş tarihi 7 gün içinde mi? Tarih formatı belirsiz olabildiği
  /// için ayrıştırılamayan değerler "yakın değil" sayılır.
  static bool _endsSoon(String? endDate, DateTime now) {
    if (endDate == null || endDate.isEmpty) return false;
    final parsed = DateTime.tryParse(endDate) ?? _tryTurkishDate(endDate);
    if (parsed == null) return false;
    final days = parsed.difference(now).inDays;
    return days >= 0 && days <= 7;
  }

  /// "31.12.2026" veya "31/12/2026" biçimini ayrıştırır.
  static DateTime? _tryTurkishDate(String s) {
    final m = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  }

  static String _tl(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₺';
  }
}
