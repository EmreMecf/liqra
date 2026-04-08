import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/app_provider.dart';
import '../kvkk/kvkk_screen.dart';
import '../widgets/app_card.dart';


/// Profil & Ayarlar Ekranı
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Profil & Ayarlar', style: AppTypography.headlineM),
                const SizedBox(height: 20),

                // ── Profil kartı ─────────────────────────────────────────────
                AppCard(
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentGreen, AppColors.accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 24, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppTypography.headlineS),
                            const SizedBox(height: 4),
                            Text(user.email, style: AppTypography.bodyS),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accentGold.withOpacity(0.3),
                                ),
                              ),
                              child: Text(user.riskLabel,
                                style: AppTypography.labelS.copyWith(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w600,
                                )),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditProfile(context, provider),
                        child: const Icon(Icons.edit_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Finansal özet ─────────────────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finansal Profil', style: AppTypography.headlineS),
                      const SizedBox(height: 16),
                      _financialRow('Aylık Net Gelir',
                          Formatters.currency(user.monthlyIncome)),
                      _financialRow('Aylık Gider',
                          Formatters.currency(provider.monthlyExpenses)),
                      _financialRow('Net Nakit',
                          Formatters.currency(provider.netCash)),
                      _financialRow('Portföy Değeri',
                          Formatters.currency(provider.portfolio.totalValue)),
                      const SizedBox(height: 4),
                      const Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Yatırım Kapasitesi',
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              )),
                          const Spacer(),
                          Text(
                            Formatters.currency(
                                (user.monthlyIncome - provider.monthlyExpenses)
                                    .clamp(0, double.infinity)),
                            style: GoogleFonts.dmMono(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Hedefler ──────────────────────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Hedeflerim', style: AppTypography.headlineS),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add,
                                  color: AppColors.accentGreen, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...provider.goals.map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(goal.emoji ?? '🎯',
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(goal.title,
                                  style: AppTypography.bodyM.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ))),
                                Text(
                                  '%${goal.progressPercent.toStringAsFixed(0)}',
                                  style: GoogleFonts.dmMono(
                                    color: AppColors.accentGreen, fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (_, constraints) => Stack(
                                children: [
                                  Container(height: 5,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgTertiary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: goal.progress),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, __) => Container(
                                      height: 5,
                                      width: constraints.maxWidth * v,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.accentGreen, Color(0xFF00F5A0)],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  Formatters.currency(goal.currentAmount),
                                  style: AppTypography.labelS.copyWith(
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                                Text(' / ', style: AppTypography.labelS),
                                Text(
                                  Formatters.currency(goal.targetAmount),
                                  style: AppTypography.labelS,
                                ),
                                const Spacer(),
                                Text(
                                  'Hedef: ${Formatters.date(goal.deadline)}',
                                  style: AppTypography.labelS,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ).animate(delay: 160.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Bildirimler ───────────────────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bildirim Tercihleri', style: AppTypography.headlineS),
                      const SizedBox(height: 12),
                      _NotificationToggle(
                        label: 'Aylık AI Raporu',
                        subtitle: 'Her ayın 1\'inde otomatik analiz',
                        value: true,
                        icon: Icons.analytics_outlined,
                      ),
                      _NotificationToggle(
                        label: 'Bütçe Aşımı Uyarısı',
                        subtitle: 'Kategori limiti aşıldığında',
                        value: true,
                        icon: Icons.warning_amber_outlined,
                      ),
                      _NotificationToggle(
                        label: 'Piyasa Alarmı',
                        subtitle: 'Belirlediğiniz fiyat eşiklerinde',
                        value: false,
                        icon: Icons.notifications_active_outlined,
                      ),
                    ],
                  ),
                ).animate(delay: 240.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Veri & Gizlilik ───────────────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Veri & Gizlilik', style: AppTypography.headlineS),
                      const SizedBox(height: 12),
                      _SettingsRow(
                        icon: Icons.download_outlined,
                        label: 'Verileri Dışa Aktar (CSV)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KvkkScreen()),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.lock_outline,
                        label: 'Gizlilik Politikası (KVKK)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KvkkScreen()),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.delete_outline,
                        label: 'Hesabı Sil',
                        textColor: AppColors.accentRed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KvkkScreen()),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Abonelik ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGold.withOpacity(0.15),
                        AppColors.accentAmber.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Premium\'a Geç', style: AppTypography.headlineS),
                            const SizedBox(height: 4),
                            Text(
                              'Sınırsız AI sorgusu + canlı piyasa verisi',
                              style: AppTypography.bodyS,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.bgPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Yakında'),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // ── Çıkış Yap ─────────────────────────────────────────
                AppCard(
                  child: _SettingsRow(
                    icon: Icons.logout,
                    label: 'Çıkış Yap',
                    textColor: AppColors.accentRed,
                    onTap: () => _showSignOutDialog(context, provider),
                  ),
                ).animate(delay: 440.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 32),

                // Versiyon bilgisi
                Center(
                  child: Text(
                    'Liqra v1.0.0\nGemini AI desteklidir',
                    style: AppTypography.labelS,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _financialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodyM),
          const Spacer(),
          Text(value, style: GoogleFonts.dmMono(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Çıkış Yap', style: AppTypography.headlineS),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: AppTypography.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.bodyM.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.signOut();
            },
            child: Text('Çıkış Yap', style: AppTypography.bodyM.copyWith(
              color: AppColors.accentRed, fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(provider: provider),
    );
  }

}

class _NotificationToggle extends StatefulWidget {
  final String label;
  final String subtitle;
  final bool value;
  final IconData icon;

  const _NotificationToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: AppTypography.bodyM.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                )),
                Text(widget.subtitle, style: AppTypography.labelS),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
            activeColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
            inactiveThumbColor: AppColors.textDisabled,
            inactiveTrackColor: AppColors.bgTertiary,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyM.copyWith(
                    color: textColor ?? AppColors.textPrimary,
                  )),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.labelS.copyWith(
                      color: AppColors.textDisabled,
                    )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Profil Düzenleme Sheet ─────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final AppProvider provider;
  const _EditProfileSheet({required this.provider});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _incomeCtrl;
  late String _riskProfile;
  bool _saving = false;

  static const _riskOptions = [
    ('low',  'Düşük Risk',  '🛡️'),
    ('mid',  'Orta Risk',   '⚖️'),
    ('high', 'Yüksek Risk', '🚀'),
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.provider.user;
    _nameCtrl   = TextEditingController(text: user.name);
    _incomeCtrl = TextEditingController(
      text: user.monthlyIncome > 0 ? user.monthlyIncome.toInt().toString() : '',
    );
    _riskProfile = user.riskProfile;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name   = _nameCtrl.text.trim();
    final income = double.tryParse(_incomeCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (name.isEmpty) return;

    setState(() => _saving = true);

    final updated = UserModel(
      id:            widget.provider.user.id,
      name:          name,
      email:         widget.provider.user.email,
      riskProfile:   _riskProfile,
      monthlyIncome: income,
      currency:      'TRY',
    );

    await widget.provider.updateUser(updated);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Profili Düzenle', style: AppTypography.headlineS),
          const SizedBox(height: 20),

          // İsim
          _field(
            label: 'Ad Soyad',
            controller: _nameCtrl,
            hint: 'Adınızı girin',
          ),
          const SizedBox(height: 16),

          // Aylık gelir
          _field(
            label: 'Aylık Net Gelir (TL)',
            controller: _incomeCtrl,
            hint: '0',
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // Risk profili
          Text('Risk Profili', style: AppTypography.labelM),
          const SizedBox(height: 10),
          Row(
            children: _riskOptions.map(((String val, String label, String icon) option) {
              final selected = _riskProfile == option.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskProfile = option.$1),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: option.$1 != 'high' ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentGreen.withOpacity(0.12)
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentGreen
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(option.$3, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(option.$2,
                            style: AppTypography.labelS.copyWith(
                              color: selected
                                  ? AppColors.accentGreen
                                  : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.bgPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bgPrimary,
                      ),
                    )
                  : Text('Kaydet', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelM),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled),
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
        ),
      ],
    );
  }
}
