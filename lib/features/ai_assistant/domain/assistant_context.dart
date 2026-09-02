/// Asistanın kullanıcı hakkında bildiği HER ŞEY — tek bir yapı.
///
/// ── Neden ───────────────────────────────────────────────────────────────────
/// Asistan eskiden yalnızca beş şey görüyordu: risk profili, aylık gelir/gider,
/// tek satırlık işlem özeti ve tek satırlık portföy özeti. Kredi kartı borcunu,
/// ekstre tarihini, aboneliklerini, hangi hissede kaç lot olduğunu, piyasa
/// fiyatlarını, haberleri ve kampanyaları hiç bilmiyordu — bu yüzden verdiği
/// tavsiyeler genel geçer kalıyordu.
///
/// Bu dosya saf veri ve saf metin üretimidir: Flutter'a bağımlı değildir,
/// test edilebilir. Toplama işi [AssistantContextBuilder] tarafından yapılır.
library;

// ── Yardımcılar ──────────────────────────────────────────────────────────────

String _tl(double v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}$buf ₺';
}

String _pct(double v, {int digits = 1}) =>
    '${v >= 0 ? '+' : ''}${v.toStringAsFixed(digits)}%';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

// ── Parçalar ─────────────────────────────────────────────────────────────────

/// Nakit ve borç durumu.
class CashSnapshot {
  final double bankBalance;
  final double cardDebt; // toplam kart borcu
  final double statementDebt; // kesilmiş ekstreler
  final double unbilled; // kesim sonrası, henüz faturalanmamış
  final double creditLimit;
  final double loanRemaining;
  final double loanMonthly;

  const CashSnapshot({
    this.bankBalance = 0,
    this.cardDebt = 0,
    this.statementDebt = 0,
    this.unbilled = 0,
    this.creditLimit = 0,
    this.loanRemaining = 0,
    this.loanMonthly = 0,
  });

  double get netWorth => bankBalance - cardDebt - loanRemaining;
  double get utilization => creditLimit > 0 ? cardDebt / creditLimit : 0;
  double get availableLimit => creditLimit - cardDebt;

  String get promptLine => [
        'Banka: ${_tl(bankBalance)}',
        'Kart borcu: ${_tl(cardDebt)} (ekstre ${_tl(statementDebt)}, '
            'ekstre dışı ${_tl(unbilled)})',
        'Kart limiti: ${_tl(creditLimit)} — kullanım %${(utilization * 100).round()}',
        if (loanRemaining > 0)
          'Kredi kalan: ${_tl(loanRemaining)}, aylık taksit ${_tl(loanMonthly)}',
        'Net servet: ${_tl(netWorth)}',
      ].join(' | ');
}

/// Yaklaşan veya gecikmiş kart ödemesi.
class CardDue {
  final String name;
  final double statementBalance;
  final double minimumPayment;
  final DateTime dueDate;
  final int daysUntilDue;
  final bool isOverdue;
  final int daysPastDue;

  const CardDue({
    required this.name,
    required this.statementBalance,
    required this.minimumPayment,
    required this.dueDate,
    required this.daysUntilDue,
    required this.isOverdue,
    required this.daysPastDue,
  });

  String get promptLine => isOverdue
      ? '$name: ${_tl(statementBalance)} — $daysPastDue gün GECİKMİŞ '
          '(vade ${_date(dueDate)})'
      : '$name: ${_tl(statementBalance)} — son ödeme ${_date(dueDate)} '
          '($daysUntilDue gün), asgari ${_tl(minimumPayment)}';
}

/// Bir kategorinin bütçe limiti ve bu ayki kullanımı.
class BudgetLine {
  final String category;
  final double limit;
  final double spent;

  const BudgetLine({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;
  double get ratio => limit > 0 ? spent / limit : 0;
  bool get isOver => spent > limit;
  bool get isNear => !isOver && ratio >= 0.80;
  double get overspend => isOver ? spent - limit : 0;
}

/// Yaklaşan abonelik yenilemesi.
class UpcomingCharge {
  final String label;
  final double amount;
  final DateTime dueDate;

  const UpcomingCharge({
    required this.label,
    required this.amount,
    required this.dueDate,
  });

  int daysUntil(DateTime now) =>
      DateTime(dueDate.year, dueDate.month, dueDate.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
}

/// Bu ay ve geçen ayın harcama tablosu.
class SpendingSnapshot {
  final double income;
  final double expenses;
  final double invested;

  /// Türkçe kategori etiketi → tutar (bu ay)
  final Map<String, double> byCategory;

  /// Türkçe kategori etiketi → tutar (geçen ay)
  final Map<String, double> previousByCategory;

  /// Aylık sabit gider (aktif abonelikler)
  final double subscriptionBurden;
  final int subscriptionCount;

  /// Yakında yenilenecek abonelikler — kullanıcı sürpriz çekimle
  /// karşılaşmasın diye.
  final List<UpcomingCharge> upcomingCharges;

  /// Kullanıcının koyduğu aylık kategori limitleri ve kullanımları.
  /// Limit koymamışsa boştur — asistan o zaman limitten hiç bahsetmez.
  final List<BudgetLine> budgets;

  const SpendingSnapshot({
    this.income = 0,
    this.expenses = 0,
    this.invested = 0,
    this.byCategory = const {},
    this.previousByCategory = const {},
    this.subscriptionBurden = 0,
    this.subscriptionCount = 0,
    this.upcomingCharges = const [],
    this.budgets = const [],
  });

  double get net => income - expenses;
  double get previousTotal =>
      previousByCategory.values.fold(0.0, (a, b) => a + b);

  double get savingsRate => income > 0 ? (income - expenses) / income : 0;

  /// Kategorileri tutara göre sıralar.
  List<MapEntry<String, double>> get sortedCategories {
    final list = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Geçen aya göre kategori bazında değişim (yeni − eski).
  Map<String, double> get categoryDeltas {
    final keys = {...byCategory.keys, ...previousByCategory.keys};
    return {
      for (final k in keys)
        k: (byCategory[k] ?? 0) - (previousByCategory[k] ?? 0),
    };
  }

  String get promptBlock {
    final lines = <String>[
      'Gelir ${_tl(income)} | Gider ${_tl(expenses)} | '
          'Net ${_tl(net)} | Yatırıma aktarılan ${_tl(invested)}',
      'Tasarruf oranı: %${(savingsRate * 100).round()}',
    ];

    if (byCategory.isNotEmpty) {
      final deltas = categoryDeltas;
      final rows = sortedCategories.take(8).map((e) {
        final d = deltas[e.key] ?? 0;
        final trend = previousByCategory.containsKey(e.key)
            ? ' (geçen aya göre ${d >= 0 ? '+' : ''}${_tl(d)})'
            : ' (geçen ay yok)';
        return '  • ${e.key}: ${_tl(e.value)}$trend';
      }).join('\n');
      lines.add('Kategoriler:\n$rows');
    }

    if (subscriptionCount > 0) {
      lines.add('Abonelikler: $subscriptionCount adet, '
          'aylık ${_tl(subscriptionBurden)}');
    }

    if (budgets.isNotEmpty) {
      final rows = budgets.map((b) {
        final state = b.isOver
            ? 'AŞILDI (+${_tl(b.overspend)})'
            : '${_tl(b.remaining)} kaldı';
        return '  • ${b.category}: ${_tl(b.spent)} / ${_tl(b.limit)} '
            '(%${(b.ratio * 100).round()}) — $state';
      }).join('\n');
      lines.add('Aylık bütçe limitleri:\n$rows');
    }

    if (upcomingCharges.isNotEmpty) {
      final rows = upcomingCharges
          .map((c) => '  • ${c.label}: ${_tl(c.amount)} — ${_date(c.dueDate)}')
          .join('\n');
      lines.add('Yakında yenilenecekler:\n$rows');
    }

    return lines.join('\n');
  }
}

/// Portföydeki tek bir varlık.
class HoldingSnapshot {
  final String name;
  final String type;
  final double quantity;
  final double buyPrice;
  final double currentPrice;

  /// Piyasadan gelen günlük değişim (yoksa null).
  final double? dayChangePercent;

  const HoldingSnapshot({
    required this.name,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    this.dayChangePercent,
  });

  double get value => quantity * currentPrice;
  double get cost => quantity * buyPrice;
  double get gainLoss => value - cost;
  double get gainLossPercent =>
      buyPrice > 0 ? ((currentPrice - buyPrice) / buyPrice) * 100 : 0;
}

/// Portföyün tamamı.
class PortfolioSnapshot {
  final List<HoldingSnapshot> holdings;

  const PortfolioSnapshot({this.holdings = const []});

  double get totalValue => holdings.fold(0.0, (a, h) => a + h.value);
  double get totalCost => holdings.fold(0.0, (a, h) => a + h.cost);
  double get gainLoss => totalValue - totalCost;
  double get gainLossPercent =>
      totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

  /// Varlık türü → portföy içindeki ağırlık (0–1).
  Map<String, double> get weightByType {
    if (totalValue <= 0) return const {};
    final byType = <String, double>{};
    for (final h in holdings) {
      byType[h.type] = (byType[h.type] ?? 0) + h.value;
    }
    return byType.map((k, v) => MapEntry(k, v / totalValue));
  }

  /// En büyük tek pozisyonun ağırlığı — yoğunlaşma riski göstergesi.
  double get largestPositionWeight {
    if (totalValue <= 0 || holdings.isEmpty) return 0;
    final biggest =
        holdings.map((h) => h.value).reduce((a, b) => a > b ? a : b);
    return biggest / totalValue;
  }

  String get promptBlock {
    if (holdings.isEmpty) return 'Portföy boş.';
    final rows = (holdings.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(15)
        .map((h) {
      final weight = totalValue > 0 ? (h.value / totalValue) * 100 : 0.0;
      final day = h.dayChangePercent == null
          ? ''
          : ', bugün ${_pct(h.dayChangePercent!, digits: 2)}';
      return '  • ${h.name} (${h.type}): ${h.quantity} adet, '
          'maliyet ${_tl(h.buyPrice)} → güncel ${_tl(h.currentPrice)}, '
          'değer ${_tl(h.value)} (%${weight.round()} ağırlık), '
          'K/Z ${_pct(h.gainLossPercent)}$day';
    }).join('\n');

    return 'Toplam ${_tl(totalValue)}, maliyet ${_tl(totalCost)}, '
        'K/Z ${_tl(gainLoss)} (${_pct(gainLossPercent)})\n$rows';
  }
}

/// Aktif finansal hedef.
class GoalSnapshot {
  final String title;
  final double target;
  final double current;
  final DateTime deadline;

  const GoalSnapshot({
    required this.title,
    required this.target,
    required this.current,
    required this.deadline,
  });

  double get remaining => (target - current).clamp(0, double.infinity);
  double get progressPercent =>
      target > 0 ? (current / target * 100).clamp(0, 100) : 0;

  /// Bugünden son tarihe kalan tam ay sayısı (en az 0).
  int get monthsLeft {
    final now = DateTime.now();
    final months =
        (deadline.year - now.year) * 12 + (deadline.month - now.month);
    return months < 0 ? 0 : months;
  }

  /// Hedefe yetişmek için ayda gereken birikim.
  double get requiredMonthly =>
      monthsLeft > 0 ? remaining / monthsLeft : remaining;

  String get promptLine =>
      '$title: ${_tl(current)} / ${_tl(target)} '
      '(%${progressPercent.round()}), son tarih ${_date(deadline)}, '
      '$monthsLeft ay kaldı → ayda ${_tl(requiredMonthly)} gerekli';
}

/// Piyasa haberi başlığı.
class NewsHeadline {
  final String title;
  final String source;
  final String category;
  final DateTime date;

  const NewsHeadline({
    required this.title,
    required this.source,
    required this.category,
    required this.date,
  });

  String get promptLine => '  • [$category] $title — $source (${_date(date)})';
}

/// Banka kampanyası.
class CampaignOffer {
  final String id;
  final String bank;
  final String title;
  final String description;
  final String category;
  final String? endDate;

  /// Cloud Functions seed verisi mi? Bu kampanyalar gerçek banka API'sinden
  /// gelmez — örnek içeriktir. Bildirime çevrilmez ve modele "örnek" olarak
  /// bildirilir; aksi hâlde asistan uydurma bir kampanyayı gerçekmiş gibi
  /// telefona bildirim olarak gönderir.
  final bool isSample;

  const CampaignOffer({
    required this.id,
    required this.bank,
    required this.title,
    required this.description,
    required this.category,
    this.endDate,
    this.isSample = false,
  });

  String get promptLine => '  • $bank — $title ($category)'
      '${endDate == null ? '' : ', son $endDate'}'
      '${isSample ? ' [ÖRNEK İÇERİK — doğrulanmamış]' : ''}';
}

/// Piyasa anlık görüntüsü — kullanıcının tuttuğu varlıklar ve ana göstergeler.
class MarketQuote {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final double dayLow;
  final double dayHigh;
  final double volume;

  const MarketQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    this.dayLow = 0,
    this.dayHigh = 0,
    this.volume = 0,
  });

  bool get hasDayRange => dayLow > 0 && dayHigh > 0 && dayHigh >= dayLow;

  /// Fiyatın gün aralığındaki konumu (0 = dip, 1 = tavan).
  double? get dayRangePosition {
    if (!hasDayRange || dayHigh == dayLow) return null;
    return ((price - dayLow) / (dayHigh - dayLow)).clamp(0.0, 1.0);
  }

  String get promptLine {
    final parts = <String>[
      '$symbol ($name): ${_tl(price)}',
      'günlük ${_pct(changePercent, digits: 2)}',
      if (hasDayRange) 'gün aralığı ${_tl(dayLow)}–${_tl(dayHigh)}',
      if (volume > 0) 'hacim ${volume.toStringAsFixed(0)}',
    ];
    return '  • ${parts.join(', ')}';
  }
}

// ── Bağlamın tamamı ──────────────────────────────────────────────────────────

class AssistantContext {
  final String userName;
  final String riskProfile;
  final DateTime now;

  final CashSnapshot cash;
  final List<CardDue> cardDues;
  final SpendingSnapshot spending;
  final PortfolioSnapshot portfolio;
  final GoalSnapshot? goal;
  final List<NewsHeadline> news;
  final List<CampaignOffer> campaigns;
  final List<MarketQuote> market;

  const AssistantContext({
    this.userName = '',
    this.riskProfile = 'dengeli',
    required this.now,
    this.cash = const CashSnapshot(),
    this.cardDues = const [],
    this.spending = const SpendingSnapshot(),
    this.portfolio = const PortfolioSnapshot(),
    this.goal,
    this.news = const [],
    this.campaigns = const [],
    this.market = const [],
  });

  /// Kullanıcının serbest nakdi: banka bakiyesinden yaklaşan ekstre borcu
  /// düşülünce kalan. Asistan "şu kadar yatırım yapabilirsin" derken bunu
  /// kullanmalı — banka bakiyesinin tamamını değil.
  double get freeCash =>
      (cash.bankBalance - cash.statementDebt).clamp(0, double.infinity);

  /// Modele gönderilen bağlam bloğu. Kısa ama eksiksiz olmalı: her satır
  /// modelin somut rakam kullanabilmesi için oradadır.
  String toPromptBlock() {
    final b = StringBuffer()
      ..writeln('## KULLANICI DURUMU (${_date(now)})')
      ..writeln();

    if (userName.isNotEmpty) b.writeln('Ad: $userName');
    b
      ..writeln('Risk profili: $riskProfile')
      ..writeln()
      ..writeln('### Nakit ve borç')
      ..writeln(cash.promptLine)
      ..writeln('Serbest nakit (ekstre düşülmüş): ${_tl(freeCash)}');

    if (cardDues.isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Kart ödemeleri');
      for (final d in cardDues) {
        b.writeln('  • ${d.promptLine}');
      }
    }

    b
      ..writeln()
      ..writeln('### Bu ayki hareket')
      ..writeln(spending.promptBlock)
      ..writeln()
      ..writeln('### Portföy')
      ..writeln(portfolio.promptBlock);

    final weights = portfolio.weightByType;
    if (weights.isNotEmpty) {
      final w = weights.entries
          .map((e) => '${e.key} %${(e.value * 100).round()}')
          .join(', ');
      b.writeln('Varlık dağılımı: $w');
    }

    if (goal != null) {
      b
        ..writeln()
        ..writeln('### Hedef')
        ..writeln(goal!.promptLine);
    }

    if (market.isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Piyasa (canlı)');
      for (final q in market.take(12)) {
        b.writeln(q.promptLine);
      }
    }

    if (news.isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Güncel haberler');
      for (final n in news.take(12)) {
        b.writeln(n.promptLine);
      }
    }

    if (campaigns.isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Kullanılabilir kampanyalar');
      for (final c in campaigns.take(10)) {
        b.writeln(c.promptLine);
      }
      if (campaigns.any((c) => c.isSample)) {
        b.writeln('NOT: "ÖRNEK İÇERİK" işaretli kampanyalar doğrulanmamış '
            'örneklerdir. Bunları gerçek teklif gibi sunma; bahsedeceksen '
            '"doğrulaman gerekir" diye belirt.');
      }
    }

    return b.toString().trimRight();
  }
}
