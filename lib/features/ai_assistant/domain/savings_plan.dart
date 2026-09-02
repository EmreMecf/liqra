import 'assistant_context.dart';

/// Planın gerçekçilik değerlendirmesi.
enum PlanFeasibility {
  /// Mevcut tasarrufla zaten yetişiyor.
  comfortable,

  /// Yetişmek için kısıntı gerekiyor ama mümkün.
  tight,

  /// Mevcut gelir-giderle imkânsız; tarih veya tutar değişmeli.
  unrealistic,
}

/// Bir harcama kaleminde önerilen kısıntı.
class SavingsCut {
  final String category;
  final double currentSpend;
  final double suggestedCut;

  /// Neden bu kalem seçildi.
  final String rationale;

  const SavingsCut({
    required this.category,
    required this.currentSpend,
    required this.suggestedCut,
    required this.rationale,
  });

  double get remainingBudget => currentSpend - suggestedCut;
  double get cutRatio => currentSpend > 0 ? suggestedCut / currentSpend : 0;
}

/// Hesaplanmış birikim planı.
///
/// ── Neden hesaplanıyor, sorulmuyor ──────────────────────────────────────────
/// "Ayda kaç lira biriktirmeliyim" bir aritmetik sorusudur. Dil modeline
/// sorulursa yanlış toplama ihtimali her zaman vardır ve kullanıcı bu rakama
/// göre karar verir. Bu yüzden **tüm sayılar burada hesaplanır**; model yalnızca
/// planı anlatır ve kısıntıların nasıl yapılacağına dair fikir verir.
class SavingsPlan {
  final String goalTitle;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final int monthsLeft;

  /// Hedefe yetişmek için ayda gereken birikim.
  final double requiredMonthly;

  /// Bugünkü gelir-gider farkı (mevcut aylık birikim kapasitesi).
  final double currentMonthly;

  /// Kapatılması gereken fark (yoksa 0).
  final double gap;

  final PlanFeasibility feasibility;
  final List<SavingsCut> cuts;

  /// Kısıntılar uygulanırsa erişilebilecek aylık birikim.
  final double achievableMonthly;

  /// Mevcut tempoyla hedefe ulaşma tarihi (kapasite yoksa null).
  final DateTime? projectedDate;

  const SavingsPlan({
    required this.goalTitle,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.monthsLeft,
    required this.requiredMonthly,
    required this.currentMonthly,
    required this.gap,
    required this.feasibility,
    required this.cuts,
    required this.achievableMonthly,
    this.projectedDate,
  });

  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  double get totalCuts => cuts.fold(0.0, (a, c) => a + c.suggestedCut);

  /// Kısıntılardan sonra hâlâ kapanmayan fark.
  double get residualGap =>
      (requiredMonthly - achievableMonthly).clamp(0, double.infinity);

  /// Modele verilecek özet — model bu rakamların ÜSTÜNE yorum yazar,
  /// rakamları kendisi hesaplamaz.
  String toPromptBlock() {
    final b = StringBuffer()
      ..writeln('## HESAPLANMIŞ BİRİKİM PLANI (rakamlar kesindir, '
          'yeniden hesaplama)')
      ..writeln('Hedef: $goalTitle')
      ..writeln('Tutar: ${_tl(targetAmount)} | '
          'Mevcut: ${_tl(currentAmount)} | Kalan: ${_tl(remaining)}')
      ..writeln('Süre: $monthsLeft ay (son tarih '
          '${deadline.day}.${deadline.month}.${deadline.year})')
      ..writeln('Gereken aylık birikim: ${_tl(requiredMonthly)}')
      ..writeln('Mevcut aylık birikim: ${_tl(currentMonthly)}')
      ..writeln('Fark: ${_tl(gap)}')
      ..writeln('Değerlendirme: ${_feasibilityLabel(feasibility)}');

    if (cuts.isNotEmpty) {
      b.writeln('Önerilen kısıntılar:');
      for (final c in cuts) {
        b.writeln('  • ${c.category}: ${_tl(c.currentSpend)} → '
            '${_tl(c.remainingBudget)} '
            '(${_tl(c.suggestedCut)} tasarruf, %${(c.cutRatio * 100).round()}) '
            '— ${c.rationale}');
      }
      b.writeln('Kısıntılarla ulaşılabilir aylık birikim: '
          '${_tl(achievableMonthly)}');
      if (residualGap > 0) {
        b.writeln('Kısıntılardan sonra kalan açık: ${_tl(residualGap)}');
      }
    }

    if (projectedDate != null && feasibility == PlanFeasibility.unrealistic) {
      b.writeln('Mevcut tempoyla tahmini ulaşma tarihi: '
          '${projectedDate!.month}.${projectedDate!.year}');
    }

    return b.toString().trimRight();
  }

  static String _feasibilityLabel(PlanFeasibility f) => switch (f) {
        PlanFeasibility.comfortable => 'Rahat — mevcut birikimle yetişiyor',
        PlanFeasibility.tight => 'Sıkı — kısıntıyla mümkün',
        PlanFeasibility.unrealistic =>
          'Gerçekçi değil — tarih veya tutar değişmeli',
      };

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

/// Planı bağlamdan hesaplar.
class SavingsPlanBuilder {
  const SavingsPlanBuilder._();

  /// Kısıntı yapılabilecek kategoriler ve makul üst sınırları.
  ///
  /// Kira, fatura, sağlık gibi zorunlu kalemler burada YOKTUR — asistan
  /// kullanıcıya kirasını kısmasını öneremez.
  static const _flexible = <String, double>{
    'Yeme-İçme': 0.35,
    'Eğlence': 0.50,
    'Alışveriş': 0.40,
    'Giyim': 0.40,
    'Market': 0.15,
    'Ulaşım': 0.15,
    'Abonelik': 0.50,
    'Diğer': 0.30,
  };

  /// Hedefsiz de plan yapılabilir: [target] ve [deadline] doğrudan verilir.
  static SavingsPlan build({
    required AssistantContext ctx,
    required String goalTitle,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
  }) {
    final now = ctx.now;
    var monthsLeft =
        (deadline.year - now.year) * 12 + (deadline.month - now.month);
    if (monthsLeft < 0) monthsLeft = 0;

    final remaining =
        (targetAmount - currentAmount).clamp(0.0, double.infinity);
    final requiredMonthly =
        monthsLeft > 0 ? remaining / monthsLeft : remaining;

    final currentMonthly = ctx.spending.net;
    final gap = (requiredMonthly - currentMonthly).clamp(0.0, double.infinity);

    final cuts = gap > 0 ? _suggestCuts(ctx, gap) : <SavingsCut>[];
    final achievableMonthly =
        currentMonthly + cuts.fold(0.0, (a, c) => a + c.suggestedCut);

    final feasibility = gap <= 0
        ? PlanFeasibility.comfortable
        : achievableMonthly >= requiredMonthly
            ? PlanFeasibility.tight
            : PlanFeasibility.unrealistic;

    // Mevcut kapasiteyle gerçekten ne zaman biter?
    DateTime? projected;
    if (achievableMonthly > 0 && remaining > 0) {
      final months = (remaining / achievableMonthly).ceil();
      projected = DateTime(now.year, now.month + months, 1);
    }

    return SavingsPlan(
      goalTitle: goalTitle,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      monthsLeft: monthsLeft,
      requiredMonthly: requiredMonthly,
      currentMonthly: currentMonthly,
      gap: gap,
      feasibility: feasibility,
      cuts: cuts,
      achievableMonthly: achievableMonthly,
      projectedDate: projected,
    );
  }

  /// Aktif hedeften plan üretir.
  static SavingsPlan? fromGoal(AssistantContext ctx) {
    final goal = ctx.goal;
    if (goal == null) return null;
    return build(
      ctx: ctx,
      goalTitle: goal.title,
      targetAmount: goal.target,
      currentAmount: goal.current,
      deadline: goal.deadline,
    );
  }

  /// En büyük esnek kalemlerden başlayarak açığı kapatmaya çalışır.
  /// Gereğinden fazla kısıntı önermez — açık kapandığında durur.
  static List<SavingsCut> _suggestCuts(AssistantContext ctx, double gap) {
    final candidates = ctx.spending.sortedCategories
        .where((e) => _flexibleRatio(e.key) != null && e.value > 0)
        .toList();

    final cuts = <SavingsCut>[];
    var covered = 0.0;

    for (final entry in candidates) {
      if (covered >= gap) break;

      final ratio = _flexibleRatio(entry.key)!;
      final maxCut = entry.value * ratio;
      if (maxCut < 50) continue; // anlamsız küçük kısıntı önerme

      final needed = gap - covered;
      final cut = maxCut < needed ? maxCut : needed;
      covered += cut;

      cuts.add(SavingsCut(
        category: entry.key,
        currentSpend: entry.value,
        suggestedCut: cut,
        rationale: cut >= maxCut
            ? 'bu kalemde makul üst sınır %${(ratio * 100).round()}'
            : 'açığı kapatmak için %${(cut / entry.value * 100).round()} yeterli',
      ));
    }

    return cuts;
  }

  /// Kategori etiketini esnek listede arar (büyük/küçük harf duyarsız).
  static double? _flexibleRatio(String label) {
    for (final e in _flexible.entries) {
      if (e.key.toLowerCase() == label.toLowerCase()) return e.value;
    }
    return null;
  }
}
