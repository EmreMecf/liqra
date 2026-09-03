import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'features/accounts/domain/entities/account_transaction_entity.dart';
import 'features/accounts/domain/entities/financial_account_entity.dart';
import 'features/accounts/domain/entities/loan_entity.dart';
import 'features/accounts/presentation/widgets/account_transaction_tile.dart';
import 'features/accounts/presentation/widgets/bank_account_card.dart';
import 'features/accounts/presentation/widgets/credit_card_widget.dart';
import 'features/accounts/presentation/widgets/loan_card_widget.dart';
import 'features/ai_assistant/domain/assistant_insight.dart';
import 'features/ai_assistant/presentation/widgets/insight_card.dart';
import 'presentation/widgets/app_card.dart';
import 'presentation/widgets/delta_chip.dart';
import 'presentation/widgets/status_banners.dart';

/// Tasarım önizleme girişi — **Firebase'e hiç dokunmaz**.
///
/// ── Neden var ───────────────────────────────────────────────────────────────
/// Uygulamanın kendisi `google-services.json` olmadan derlenmiyor, bu yüzden
/// bileşenlerin nasıl göründüğü ancak cihaza kurulunca anlaşılabiliyordu.
/// Bu giriş bileşenleri sahte veriyle yan yana dizer; tarayıcıda saniyeler
/// içinde açılır ve tutarsızlıklar (farklı köşe yarıçapı, kayan hizalar,
/// çakışan renkler) doğrudan görünür.
///
/// ```bash
/// flutter run -d chrome -t lib/design_preview.dart
/// ```
void main() => runApp(const DesignPreviewApp());

class DesignPreviewApp extends StatelessWidget {
  const DesignPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liqra — Tasarım Önizleme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGreen,
          secondary: AppColors.accentAmber,
          surface: AppColors.bgSecondary,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.bgPrimary,
      ),
      home: const _Gallery(),
    );
  }
}

// ── Sahte veri ───────────────────────────────────────────────────────────────

final _now = DateTime(2026, 9, 3);

CreditCardEntity _card({
  required String name,
  required BankName bank,
  double limit = 50000,
  double used = 18400,
  double statement = 12250,
  double minimum = 2450,
  int closingDay = 15,
  int dueDay = 5,
}) =>
    CreditCardEntity(
      id: name,
      userId: 'u',
      name: name,
      bank: bank,
      creditLimit: limit,
      usedAmount: used,
      statementBalance: statement,
      minimumPayment: minimum,
      statementClosingDay: closingDay,
      paymentDueDay: dueDay,
      maskedCardNumber: '4417',
      createdAt: DateTime(2024, 1, 1),
    );

final _bankAccount = BankAccountEntity(
  id: 'b1',
  userId: 'u',
  name: 'Maaş Hesabı',
  bank: BankName.isbank,
  balance: 42350.75,
  iban: 'TR33 0006 1005 1978 6457 8413 26',
  createdAt: DateTime(2024, 1, 1),
);

final _loan = LoanEntity(
  id: 'l1',
  userId: 'u',
  name: 'İhtiyaç Kredisi',
  bank: BankName.yapikredi,
  totalAmount: 120000,
  remainingAmount: 74500,
  monthlyPayment: 6200,
  interestRate: 3.29,
  totalInstallments: 24,
  remainingInstallments: 13,
  paymentDueDay: 12,
  startDate: DateTime(2025, 4, 12),
  createdAt: DateTime(2025, 4, 12),
);

AccountTransactionEntity _tx({
  required String description,
  required double amount,
  required String type,
  String category = 'market',
  bool installment = false,
  int count = 1,
  int number = 1,
}) =>
    AccountTransactionEntity(
      id: description,
      accountId: 'a',
      userId: 'u',
      amount: amount,
      description: description,
      date: _now,
      type: type,
      category: category,
      isInstallment: installment,
      installmentCount: count,
      installmentNumber: number,
    );

const _insights = <AssistantInsight>[
  AssistantInsight(
    id: '1',
    severity: InsightSeverity.critical,
    emoji: '🚨',
    title: 'Bonus ödemesi 4 gün gecikti',
    body: '12.250 ₺ ödemen vadesini geçti. Gecikme faizi işliyor ve '
        'kredi notunu etkiliyor.',
    action: 'Hemen öde',
    route: '/accounts',
  ),
  AssistantInsight(
    id: '2',
    severity: InsightSeverity.warning,
    emoji: '📊',
    title: 'Yeme-İçme harcaman %64 arttı',
    body: 'Geçen ay 3.400 ₺ idi, bu ay 5.580 ₺. Fark 2.180 ₺.',
    route: '/spending',
  ),
  AssistantInsight(
    id: '3',
    severity: InsightSeverity.opportunity,
    emoji: '💡',
    title: '84.000 ₺ atıl duruyor',
    body: 'Acil fon için 60.000 ₺ ayırdıktan sonra kalan tutar vadesiz '
        'hesapta enflasyona karşı eriyor.',
    action: 'Nereye yatırayım?',
    route: '/ai',
  ),
  AssistantInsight(
    id: '4',
    severity: InsightSeverity.info,
    emoji: '✅',
    title: 'Tasarruf oranın %31',
    body: 'Bu ay 14.200 ₺ artırdın. Bu tempoyla yılda 170.400 ₺ birikir.',
    route: '/ai',
  ),
];

// ── Galeri ───────────────────────────────────────────────────────────────────

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Telefon genişliği — bileşenler gerçek ortamındaki gibi dursun
          child: SizedBox(
            width: 420,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                const _SectionTitle('Durum bantları'),
                const StaleDataBanner(lastUpdated: null),
                StaleDataBanner(
                    lastUpdated: _now.subtract(const Duration(hours: 6))),

                const _SectionTitle('Asistan içgörüleri'),
                const InsightList(insights: _insights, limit: 4),

                const _SectionTitle('Kredi kartı'),
                _Pad(child: CreditCardWidget(
                    card: _card(name: 'Bonus', bank: BankName.garanti))),
                _Pad(child: CreditCardWidget(
                  card: _card(
                    name: 'Maximum',
                    bank: BankName.isbank,
                    limit: 20000,
                    used: 21400,
                    statement: 0,
                    minimum: 0,
                  ),
                )),
                _Pad(child: CreditCardWidget(
                  card: _card(
                    name: 'Axess',
                    bank: BankName.akbank,
                    used: 2100,
                    statement: 0,
                    minimum: 0,
                  ),
                )),

                const _SectionTitle('Banka hesabı'),
                _Pad(child: BankAccountCard(account: _bankAccount)),

                const _SectionTitle('Kredi'),
                _Pad(child: LoanCardWidget(loan: _loan)),

                const _SectionTitle('İşlem satırı'),
                _Pad(
                  child: Column(children: [
                    AccountTransactionTile(
                        tx: _tx(
                            description: 'Migros',
                            amount: 842.50,
                            type: 'expense')),
                    AccountTransactionTile(
                        tx: _tx(
                            description: 'Maaş',
                            amount: 62000,
                            type: 'income',
                            category: 'maas')),
                    AccountTransactionTile(
                      tx: _tx(
                        description: 'Teknoloji Mağazası (3/12)',
                        amount: 1250,
                        type: 'expense',
                        category: 'teknoloji',
                        installment: true,
                        count: 12,
                        number: 3,
                      ),
                    ),
                  ]),
                ),

                const _SectionTitle('Değişim rozeti'),
                _Pad(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      DeltaChip(value: 12.4),
                      DeltaChip(value: -6.1),
                      DeltaChip(value: 0),
                      DeltaChip(value: 148.9),
                    ],
                  ),
                ),

                const _SectionTitle('Kart yüzeyi'),
                _Pad(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Başlık', style: AppTypography.headlineS),
                        const SizedBox(height: 6),
                        Text(
                          'AppCard içindeki gövde metni. Kart zemini, kenarlık '
                          've köşe yarıçapı buradan geliyor.',
                          style: AppTypography.bodyM,
                        ),
                      ],
                    ),
                  ),
                ),

                const _SectionTitle('Tipografi ölçeği'),
                _Pad(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('display', style: AppTypography.display),
                      Text('headlineL', style: AppTypography.headlineL),
                      Text('headlineM', style: AppTypography.headlineM),
                      Text('headlineS', style: AppTypography.headlineS),
                      const SizedBox(height: 8),
                      Text('289.847,50 ₺', style: AppTypography.numberXL),
                      Text('289.847,50 ₺', style: AppTypography.numberL),
                      Text('289.847,50 ₺', style: AppTypography.numberM),
                      const SizedBox(height: 8),
                      Text('bodyL — gövde metni', style: AppTypography.bodyL),
                      Text('bodyM — gövde metni', style: AppTypography.bodyM),
                      Text('bodyS — gövde metni', style: AppTypography.bodyS),
                      Text('labelM', style: AppTypography.labelM),
                      Text('CAPSLABEL', style: AppTypography.capsLabel),
                    ],
                  ),
                ),

                const _SectionTitle('Renk paleti'),
                const _Pad(child: _Swatches()),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Text(text.toUpperCase(),
            style: AppTypography.capsLabel
                .copyWith(color: AppColors.accentGreen)),
      );
}

class _Pad extends StatelessWidget {
  final Widget child;
  const _Pad({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  static const _colors = <String, Color>{
    'accentGreen': AppColors.accentGreen,
    'accentTeal': AppColors.accentTeal,
    'accentAmber': AppColors.accentAmber,
    'goldBright': AppColors.goldBright,
    'accentRed': AppColors.accentRed,
    'accentBlue': AppColors.accentBlue,
    'accentPurple': AppColors.accentPurple,
    'bgSecondary': AppColors.bgSecondary,
    'bgTertiary': AppColors.bgTertiary,
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'textDisabled': AppColors.textDisabled,
  };

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _colors.entries
            .map((e) => Column(
                  children: [
                    Container(
                      width: 62,
                      height: 40,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 62,
                      child: Text(e.key,
                          textAlign: TextAlign.center,
                          style: AppTypography.capsLabel
                              .copyWith(fontSize: 8)),
                    ),
                  ],
                ))
            .toList(),
      );
}
