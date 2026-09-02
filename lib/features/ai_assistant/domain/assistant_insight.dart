import 'assistant_context.dart';

/// Bir içgörünün aciliyeti. Sıralama ve renk buna göre yapılır.
enum InsightSeverity { critical, warning, opportunity, info }

/// Asistanın kendiliğinden ürettiği bir bulgu.
///
/// [id] bildirimlerin tekrarlanmaması için kullanılır — aynı gün aynı id ile
/// ikinci bir bildirim gönderilmez (bkz. AssistantNotifier).
class AssistantInsight {
  final String id;
  final InsightSeverity severity;
  final String emoji;
  final String title;
  final String body;

  /// Kullanıcının atacağı adım — yoksa null.
  final String? action;

  /// Dokunulduğunda gidilecek ekran (bkz. AppRoutes).
  final String? route;

  /// Bildirim olarak gönderilmeye değer mi? (İçgörülerin çoğu yalnızca
  /// uygulama içinde gösterilir; kullanıcıyı telefonundan rahatsız etmez.)
  final bool notify;

  const AssistantInsight({
    required this.id,
    required this.severity,
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
    this.route,
    this.notify = false,
  });

  int get _rank => switch (severity) {
        InsightSeverity.critical => 0,
        InsightSeverity.warning => 1,
        InsightSeverity.opportunity => 2,
        InsightSeverity.info => 3,
      };
}

/// Bağlamdan içgörü üretir — **AI çağrısı yapmaz**.
///
/// ── Neden AI değil ──────────────────────────────────────────────────────────
/// "Ekstren 3 gün sonra ödenecek" ya da "market harcaman geçen aya göre %60
/// arttı" bilgileri hesaplanabilir gerçeklerdir. Bunları modele sordurmak hem
/// yavaş ve pahalı olur hem de modelin rakamı yanlış okuma ihtimalini davet
/// eder. Model yalnızca **yorum** için kullanılır; **tespit** burada yapılır.
class InsightEngine {
  const InsightEngine._();

  /// Kategori artışının uyarı sayılması için gereken eşikler.
  static const _categoryJumpRatio = 0.40; // geçen aya göre %40 artış
  static const _categoryJumpMinAmount = 500.0; // ve en az 500 ₺ fark

  /// Portföyde tek pozisyonun uyarı verdiği ağırlık.
  static const _concentrationLimit = 0.40;

  /// Kart kullanım oranı uyarı eşiği.
  static const _utilizationLimit = 0.70;

  static List<AssistantInsight> analyze(AssistantContext ctx) {
    final out = <AssistantInsight>[
      ..._cardInsights(ctx),
      ..._spendingInsights(ctx),
      ..._portfolioInsights(ctx),
      ..._goalInsights(ctx),
      ..._opportunityInsights(ctx),
    ];

    out.sort((a, b) => a._rank.compareTo(b._rank));
    return out;
  }

  // ── Kart ve borç ───────────────────────────────────────────────────────────

  static List<AssistantInsight> _cardInsights(AssistantContext ctx) {
    final out = <AssistantInsight>[];

    for (final d in ctx.cardDues) {
      if (d.isOverdue) {
        out.add(AssistantInsight(
          id: 'card_overdue_${d.name}',
          severity: InsightSeverity.critical,
          emoji: '🚨',
          title: '${d.name} ödemesi ${d.daysPastDue} gün gecikti',
          body: '${_tl(d.statementBalance)} ödemen vadesini geçti. '
              'Gecikme faizi işliyor ve kredi notunu etkiliyor.',
          action: 'Hemen öde',
          route: '/accounts',
          notify: true,
        ));
      } else if (d.daysUntilDue <= 3 && d.statementBalance > 0) {
        out.add(AssistantInsight(
          id: 'card_due_${d.name}',
          severity: InsightSeverity.warning,
          emoji: '⏰',
          title: d.daysUntilDue == 0
              ? '${d.name} — bugün son gün'
              : '${d.name} — ${d.daysUntilDue} gün kaldı',
          body: 'Ekstre ${_tl(d.statementBalance)}, '
              'asgari ${_tl(d.minimumPayment)}.',
          action: 'Ödeme yap',
          route: '/accounts',
          notify: true,
        ));
      }
    }

    // Ödeme gücü: yaklaşan ekstre banka bakiyesini aşıyor mu?
    final due = ctx.cardDues
        .where((d) => d.daysUntilDue <= 7 || d.isOverdue)
        .fold(0.0, (a, d) => a + d.statementBalance);
    if (due > 0 && due > ctx.cash.bankBalance) {
      out.add(AssistantInsight(
        id: 'cash_short',
        severity: InsightSeverity.critical,
        emoji: '⚠️',
        title: 'Ekstre bakiyeni aşıyor',
        body: 'Bir hafta içinde ${_tl(due)} ödemen var, '
            'banka bakiyen ${_tl(ctx.cash.bankBalance)}. '
            'Aradaki fark ${_tl(due - ctx.cash.bankBalance)}.',
        action: 'Plan yap',
        route: '/ai',
        notify: true,
      ));
    }

    if (ctx.cash.utilization >= _utilizationLimit && ctx.cash.creditLimit > 0) {
      out.add(AssistantInsight(
        id: 'utilization_high',
        severity: InsightSeverity.warning,
        emoji: '💳',
        title: 'Kart kullanımın %${(ctx.cash.utilization * 100).round()}',
        body: 'Toplam limitinin büyük kısmı dolu. '
            '%30 altına inmek kredi notunu belirgin şekilde iyileştirir.',
        route: '/accounts',
      ));
    }

    if (ctx.cash.unbilled > 0 && ctx.cash.unbilled > ctx.cash.statementDebt) {
      out.add(AssistantInsight(
        id: 'unbilled_high',
        severity: InsightSeverity.info,
        emoji: '📄',
        title: 'Gelecek ekstren şimdiden ${_tl(ctx.cash.unbilled)}',
        body: 'Kesimden sonra yaptığın harcamalar bu ekstreye girecek — '
            'şu anki ekstrenden daha büyük.',
        route: '/accounts',
      ));
    }

    return out;
  }

  // ── Harcama ────────────────────────────────────────────────────────────────

  static List<AssistantInsight> _spendingInsights(AssistantContext ctx) {
    final out = <AssistantInsight>[];
    final s = ctx.spending;

    // Gelirden fazla harcama
    if (s.income > 0 && s.expenses > s.income) {
      out.add(AssistantInsight(
        id: 'overspend_month',
        severity: InsightSeverity.critical,
        emoji: '📉',
        title: 'Bu ay gelirinden fazla harcadın',
        body: 'Gelir ${_tl(s.income)}, gider ${_tl(s.expenses)}. '
            'Açık ${_tl(s.expenses - s.income)}.',
        action: 'Nerede kestiğini gör',
        route: '/ai',
        notify: true,
      ));
    }

    // Kategori sıçraması
    final deltas = s.categoryDeltas;
    for (final e in deltas.entries) {
      final previous = s.previousByCategory[e.key] ?? 0;
      if (previous <= 0 || e.value < _categoryJumpMinAmount) continue;
      final ratio = e.value / previous;
      if (ratio < _categoryJumpRatio) continue;

      out.add(AssistantInsight(
        id: 'category_jump_${e.key}',
        severity: InsightSeverity.warning,
        emoji: '📊',
        title: '${e.key} harcaman %${(ratio * 100).round()} arttı',
        body: 'Geçen ay ${_tl(previous)} idi, bu ay '
            '${_tl(s.byCategory[e.key] ?? 0)}. '
            'Fark ${_tl(e.value)}.',
        route: '/spending',
      ));
    }

    // Abonelik yükü
    if (s.income > 0 && s.subscriptionBurden > s.income * 0.15) {
      out.add(AssistantInsight(
        id: 'subscription_burden',
        severity: InsightSeverity.warning,
        emoji: '🔁',
        title: 'Abonelikler gelirinin '
            '%${(s.subscriptionBurden / s.income * 100).round()}\'i',
        body: '${s.subscriptionCount} abonelik için ayda '
            '${_tl(s.subscriptionBurden)} ödüyorsun. '
            'Yılda ${_tl(s.subscriptionBurden * 12)} eder.',
        action: 'Abonelikleri gözden geçir',
        route: '/subscriptions',
      ));
    }

    // Bütçe limiti aşımı / yaklaşma.
    //
    // Kullanıcı limiti kendisi koydu; bunu takip etmek uygulamanın asıl işi.
    // Eskiden `notifyBudgetOverrun` yazılmıştı ama limit kavramı hiç yoktu,
    // bu yüzden hiçbir zaman çalışmıyordu.
    for (final b in s.budgets) {
      if (b.isOver) {
        out.add(AssistantInsight(
          id: 'budget_over_${b.category}',
          severity: InsightSeverity.warning,
          emoji: '🚧',
          title: '${b.category} bütçesi aşıldı',
          body: '${_tl(b.limit)} limitine karşılık ${_tl(b.spent)} harcadın. '
              '${_tl(b.overspend)} aşım var.',
          action: 'Harcamaları gör',
          route: '/spending',
          notify: true,
        ));
      } else if (b.isNear) {
        out.add(AssistantInsight(
          id: 'budget_near_${b.category}',
          severity: InsightSeverity.info,
          emoji: '📐',
          title: '${b.category} bütçesinin '
              '%${(b.ratio * 100).round()}\'i kullanıldı',
          body: 'Ay sonuna kadar ${_tl(b.remaining)} kaldı.',
          route: '/spending',
        ));
      }
    }

    // Yaklaşan abonelik çekimleri.
    //
    // Abonelik takibinin asıl değeri sürpriz çekimle karşılaşmamaktır; bu
    // hatırlatma hiç yoktu. İptal etmek isteyen kullanıcı için son şans,
    // bakiyesi yetmeyen için de uyarıdır.
    for (final charge in s.upcomingCharges) {
      final days = charge.daysUntil(ctx.now);
      if (days > 3) continue;

      final shortOnCash = ctx.cash.bankBalance < charge.amount;
      out.add(AssistantInsight(
        id: 'sub_due_${charge.label}',
        severity:
            shortOnCash ? InsightSeverity.warning : InsightSeverity.info,
        emoji: '🔁',
        title: days == 0
            ? '${charge.label} bugün yenileniyor'
            : '${charge.label} $days gün sonra yenileniyor',
        body: shortOnCash
            ? '${_tl(charge.amount)} çekilecek ama banka bakiyen '
                '${_tl(ctx.cash.bankBalance)}.'
            : '${_tl(charge.amount)} çekilecek. '
                'İptal edeceksen son şans.',
        action: 'Abonelikleri gör',
        route: '/subscriptions',
        notify: true,
      ));
    }

    // Tasarruf oranı iyi gidiyorsa söyle — asistan sadece kötü haber vermemeli
    if (s.income > 0 && s.savingsRate >= 0.20 && s.expenses > 0) {
      out.add(AssistantInsight(
        id: 'savings_good',
        severity: InsightSeverity.info,
        emoji: '✅',
        title: 'Tasarruf oranın %${(s.savingsRate * 100).round()}',
        body: 'Bu ay ${_tl(s.net)} artırdın. '
            'Bu tempoyla yılda ${_tl(s.net * 12)} birikir.',
        route: '/ai',
      ));
    }

    return out;
  }

  // ── Portföy ────────────────────────────────────────────────────────────────

  static List<AssistantInsight> _portfolioInsights(AssistantContext ctx) {
    final out = <AssistantInsight>[];
    final p = ctx.portfolio;
    if (p.holdings.isEmpty) return out;

    if (p.largestPositionWeight > _concentrationLimit) {
      final biggest = p.holdings.reduce((a, b) => a.value > b.value ? a : b);
      out.add(AssistantInsight(
        id: 'concentration_${biggest.name}',
        severity: InsightSeverity.warning,
        emoji: '🎯',
        title: 'Portföyünün %${(p.largestPositionWeight * 100).round()}\'i '
            '${biggest.name}',
        body: 'Tek bir varlıkta bu kadar yoğunlaşmak, o varlık düştüğünde '
            'portföyünün tamamını aşağı çeker.',
        action: 'Dağılımı konuş',
        route: '/ai',
      ));
    }

    // Sert günlük hareket
    for (final h in p.holdings) {
      final change = h.dayChangePercent;
      if (change == null || change.abs() < 5) continue;
      out.add(AssistantInsight(
        id: 'move_${h.name}',
        severity: InsightSeverity.info,
        emoji: change > 0 ? '📈' : '📉',
        title: '${h.name} bugün '
            '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
        body: 'Pozisyonun ${_tl(h.value)}, '
            'toplam K/Z ${h.gainLossPercent >= 0 ? '+' : ''}'
            '${h.gainLossPercent.toStringAsFixed(1)}%.',
        action: 'Analiz et',
        route: '/portfolio',
        notify: change.abs() >= 8,
      ));
    }

    return out;
  }

  // ── Hedef ──────────────────────────────────────────────────────────────────

  static List<AssistantInsight> _goalInsights(AssistantContext ctx) {
    final goal = ctx.goal;
    if (goal == null || goal.remaining <= 0) return const [];

    final needed = goal.requiredMonthly;
    final available = ctx.spending.net;

    if (goal.monthsLeft == 0) {
      return [
        AssistantInsight(
          id: 'goal_expired',
          severity: InsightSeverity.warning,
          emoji: '🎯',
          title: '${goal.title} hedefinin süresi doldu',
          body: '${_tl(goal.remaining)} eksik kaldı. '
              'Yeni bir tarih belirleyelim mi?',
          action: 'Plan oluştur',
          route: '/ai',
        ),
      ];
    }

    if (needed > available && available >= 0) {
      return [
        AssistantInsight(
          id: 'goal_behind',
          severity: InsightSeverity.warning,
          emoji: '🎯',
          title: '${goal.title} hedefinde gerideysin',
          body: 'Ayda ${_tl(needed)} biriktirmen gerekiyor ama bu ay '
              '${_tl(available)} artırdın. '
              'Aradaki fark ${_tl(needed - available)}.',
          action: 'Birikim planı yap',
          route: '/ai',
        ),
      ];
    }

    return [
      AssistantInsight(
        id: 'goal_ontrack',
        severity: InsightSeverity.info,
        emoji: '🎯',
        title: '${goal.title} hedefi yolunda',
        body: 'Ayda ${_tl(needed)} gerekiyor, bu ay ${_tl(available)} '
            'artırdın. ${goal.monthsLeft} ay kaldı.',
        route: '/ai',
      ),
    ];
  }

  // ── Fırsatlar ──────────────────────────────────────────────────────────────

  static List<AssistantInsight> _opportunityInsights(AssistantContext ctx) {
    final out = <AssistantInsight>[];

    // Atıl nakit: aylık giderinin 3 katından fazlası vadesiz hesapta duruyorsa
    final buffer = ctx.spending.expenses * 3;
    if (buffer > 0 && ctx.freeCash > buffer * 1.5) {
      out.add(AssistantInsight(
        id: 'idle_cash',
        severity: InsightSeverity.opportunity,
        emoji: '💡',
        title: '${_tl(ctx.freeCash - buffer)} atıl duruyor',
        body: 'Acil fon için ${_tl(buffer)} (3 aylık gider) ayırdıktan sonra '
            'kalan tutar vadesiz hesapta enflasyona karşı eriyor.',
        action: 'Nereye yatırayım?',
        route: '/ai',
      ));
    }

    // Acil fon yoksa uyar
    if (buffer > 0 && ctx.freeCash < ctx.spending.expenses) {
      out.add(AssistantInsight(
        id: 'no_emergency_fund',
        severity: InsightSeverity.warning,
        emoji: '🛟',
        title: 'Acil fonun bir aylık gideri karşılamıyor',
        body: 'Serbest nakdin ${_tl(ctx.freeCash)}, aylık giderin '
            '${_tl(ctx.spending.expenses)}. '
            'Önce 3 aylık bir tampon oluşturmak yatırımdan önceliklidir.',
        action: 'Plan yap',
        route: '/ai',
      ));
    }

    return out;
  }

  static String _tl(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}$buf ₺';
  }
}
