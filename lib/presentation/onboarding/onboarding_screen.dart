import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/providers/app_provider.dart';

/// Onboarding — 3 ekran (bir kez gösterilir)
/// Ekran 1: Profil | Ekran 2: Risk Anketi | Ekran 3: İlk Hedef
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Ekran 1
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();

  // Ekran 2 — Risk anketi
  final List<int> _riskAnswers = [1, 1, 1, 1]; // 0-3 arası slider değeri

  // Ekran 3 — Hedef
  final _goalTitleController = TextEditingController(text: 'Araba Almak');
  final _goalAmountController = TextEditingController(text: '400000');
  int _goalMonths = 12;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    _goalTitleController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  String _calculateRiskProfile() {
    final total = _riskAnswers.fold(0, (sum, v) => sum + v);
    if (total <= 3)  return 'low';
    if (total <= 6)  return 'mid';
    if (total <= 9)  return 'high';
    return 'very_high';
  }

  String _riskProfileLabel() {
    switch (_calculateRiskProfile()) {
      case 'low':       return 'Düşük Risk';
      case 'mid':       return 'Orta Risk';
      case 'high':      return 'Yüksek Risk';
      case 'very_high': return 'Çok Yüksek Risk';
      default:          return '';
    }
  }

  double get _goalProjection {
    final amount = double.tryParse(_goalAmountController.text) ?? 400000;
    return amount / _goalMonths;
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final provider = context.read<AppProvider>();
    final goalAmount = double.tryParse(_goalAmountController.text) ?? 0;
    final income = double.tryParse(_incomeController.text) ?? 0;

    await provider.completeOnboarding(
      name: _nameController.text.trim().isEmpty ? 'Kullanıcı' : _nameController.text.trim(),
      monthlyIncome: income,
      riskProfile: _calculateRiskProfile(),
      goalTitle: _goalTitleController.text.trim().isEmpty ? 'Hedefim' : _goalTitleController.text.trim(),
      goalAmount: goalAmount,
      goalDeadline: DateTime.now().add(Duration(days: _goalMonths * 30)),
    );
    // AuthService.markProfileComplete zaten çağrıldı — _AuthGate otomatik yönlendirir
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // İlerleme göstergesi
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? AppColors.accentGreen
                          : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            // Sayfalar
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildProfilePage(),
                  _buildRiskPage(),
                  _buildGoalPage(),
                ],
              ),
            ),

            // İleri butonu
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.bgPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < 2 ? 'Devam Et →' : 'Başla',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ekran 1: Profil ────────────────────────────────────────────────────────
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Merhaba! 👋', style: AppTypography.headlineL),
          const SizedBox(height: 8),
          Text(
            'Sizi tanıyalım. Bu bilgiler AI analizlerini kişiselleştirmek için kullanılır.',
            style: AppTypography.bodyM,
          ),
          const SizedBox(height: 48),

          _buildLabel('Adınız'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Emre Yılmaz',
            keyboardType: TextInputType.name,
          ),

          const SizedBox(height: 24),
          _buildLabel('Aylık Net Geliriniz (TL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _incomeController,
            hint: '45.000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 24),
          _buildLabel('Para Birimi Tercihi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Text('🇹🇷  Türk Lirası (TL)', style: AppTypography.bodyL.copyWith(
                  color: AppColors.textPrimary,
                )),
                const Spacer(),
                const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ekran 2: Risk Anketi ───────────────────────────────────────────────────
  Widget _buildRiskPage() {
    final questions = [
      'Yatırımlarınız %20 düşse tepkiniz ne olur?',
      'Yatırım ufkunuz ne kadar?',
      'Yatırımlarınızın ne kadarını kaybedebilirsiniz?',
      'Yüksek getiri için yüksek risk alır mısınız?',
    ];
    final options = [
      ['Hemen satarım', 'Tedirginim', 'Beklerim', 'Alım fırsatı!'],
      ['1 yıldan az', '1-3 yıl', '3-5 yıl', '5+ yıl'],
      ['%5\'ten az', '%5-15', '%15-30', '%30+'],
      ['Hayır, asla', 'Mümkün değil', 'Belki', 'Evet, kesinlikle'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Risk Profiliniz 📊', style: AppTypography.headlineL),
          const SizedBox(height: 8),
          Text('4 kısa soru — AI tavsiyelerinizi optimize eder.', style: AppTypography.bodyM),
          const SizedBox(height: 16),

          // Risk skoru göstergesi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppColors.accentGreen, size: 18),
                const SizedBox(width: 8),
                Text('Profil: ', style: AppTypography.labelM),
                Text(_riskProfileLabel(), style: AppTypography.labelM.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${questions[i]}', style: AppTypography.bodyM.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                    )),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accentGreen,
                        inactiveTrackColor: AppColors.borderSubtle,
                        thumbColor: AppColors.accentGreen,
                        overlayColor: AppColors.accentGreen.withOpacity(0.1),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _riskAnswers[i].toDouble(),
                        min: 0,
                        max: 3,
                        divisions: 3,
                        onChanged: (v) => setState(() => _riskAnswers[i] = v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: options[i].map((opt) => Text(opt, style: AppTypography.labelS)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ekran 3: İlk Hedef ────────────────────────────────────────────────────
  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('İlk Hedefiniz 🎯', style: AppTypography.headlineL),
          const SizedBox(height: 8),
          Text(
            'Büyük bir hedef belirleyin. AI her ay hedefinize olan ilerlemenizi takip eder.',
            style: AppTypography.bodyM,
          ),
          const SizedBox(height: 48),

          _buildLabel('Hedef Adı'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _goalTitleController,
            hint: 'Araba Almak',
          ),

          const SizedBox(height: 24),
          _buildLabel('Hedef Tutar (TL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _goalAmountController,
            hint: '400.000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 24),
          _buildLabel('Süre: $_goalMonths ay'),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentGreen,
              inactiveTrackColor: AppColors.borderSubtle,
              thumbColor: AppColors.accentGreen,
              trackHeight: 3,
            ),
            child: Slider(
              value: _goalMonths.toDouble(),
              min: 3,
              max: 60,
              divisions: 57,
              onChanged: (v) => setState(() => _goalMonths = v.round()),
            ),
          ),

          const SizedBox(height: 16),
          // Projeksiyon kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGreen.withOpacity(0.1),
                  AppColors.accentBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Hedefinize ulaşmak için aylık ',
                      style: AppTypography.bodyM,
                      children: [
                        TextSpan(
                          text: '${_formatAmount(_goalProjection)} TL',
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' yatırım gerekiyor.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Yardımcı widgetlar ─────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(text, style: AppTypography.labelM.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.outfit(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textDisabled,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  String _formatAmount(double amount) {
    final int rounded = amount.round();
    final String raw = rounded.toString();
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = raw.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(raw[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
