import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
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
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withAlpha(70),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: AppColors.accentBlue.withAlpha(30),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: AppColors.textSecondary, size: 16),
                        ),
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
                            onTap: () => _showAddGoal(context, provider),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withAlpha(28),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: AppColors.accentGreen.withAlpha(80),
                                ),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: AppColors.accentGreen, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (provider.goals.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 8),
                                Text('Henüz hedef eklemediniz',
                                    style: AppTypography.bodyM.copyWith(
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text('+ butonuna basarak hedef ekleyin',
                                    style: AppTypography.labelS.copyWith(
                                        color: AppColors.textDisabled)),
                              ],
                            ),
                          ),
                        ),
                      ...provider.goals.map((goal) => GestureDetector(
                        onTap: () => _showEditGoal(context, provider, goal),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
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
                                      color: goal.isCompleted
                                          ? AppColors.accentGreen
                                          : AppColors.accentAmber,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 14, color: AppColors.textDisabled),
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
                                          gradient: LinearGradient(
                                            colors: goal.isCompleted
                                                ? [AppColors.accentGreen, const Color(0xFF00F5A0)]
                                                : [AppColors.accentAmber, AppColors.accentGreen],
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(' / ', style: AppTypography.labelS),
                                  Text(
                                    Formatters.currency(goal.targetAmount),
                                    style: AppTypography.labelS,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Son: ${Formatters.date(goal.deadline)}',
                                    style: AppTypography.labelS.copyWith(
                                      color: goal.deadline.isBefore(DateTime.now())
                                          ? AppColors.accentRed
                                          : AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        prefKey: 'notif_monthly_ai',
                      ),
                      _NotificationToggle(
                        label: 'Bütçe Aşımı Uyarısı',
                        subtitle: 'Kategori limiti aşıldığında',
                        value: true,
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.accentAmber,
                        prefKey: 'notif_budget_warn',
                      ),
                      _NotificationToggle(
                        label: 'Piyasa Alarmı',
                        subtitle: 'Belirlediğiniz fiyat eşiklerinde',
                        value: false,
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.accentBlue,
                        prefKey: 'notif_market_alarm',
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
                        icon: Icons.download_rounded,
                        iconColor: AppColors.accentGreen,
                        label: 'Verileri Dışa Aktar (CSV)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KvkkScreen()),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.lock_rounded,
                        iconColor: AppColors.accentBlue,
                        label: 'Gizlilik Politikası (KVKK)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KvkkScreen()),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.delete_rounded,
                        iconColor: AppColors.accentRed,
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
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.accentRed,
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

  void _showAddGoal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GoalSheet(provider: provider),
    );
  }

  void _showEditGoal(BuildContext context, AppProvider provider, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GoalSheet(provider: provider, existing: goal),
    );
  }

}

class _NotificationToggle extends StatefulWidget {
  final String label;
  final String subtitle;
  final bool value;
  final IconData icon;
  final Color iconColor;
  final String prefKey;

  const _NotificationToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.prefKey,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(widget.prefKey);
    if (mounted) setState(() => _value = saved ?? widget.value);
  }

  Future<void> _toggle(bool v) async {
    setState(() => _value = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: widget.iconColor.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 18),
          ),
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
            onChanged: _toggle,
            activeColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withAlpha(76),
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
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.subtitle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iColor.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iColor, size: 18),
            ),
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
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withAlpha(120), size: 16),
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

// ── Hedef Ekleme / Düzenleme Sheet ────────────────────────────────────────────

class _GoalSheet extends StatefulWidget {
  final AppProvider provider;
  final GoalModel? existing;

  const _GoalSheet({required this.provider, this.existing});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late DateTime _deadline;
  late String _emoji;
  bool _saving = false;

  static const _emojis = ['🎯','🏠','🚗','✈️','💻','📱','🎓','💍','👶','🌴','💰','🏋️'];

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleCtrl   = TextEditingController(text: g?.title ?? '');
    _targetCtrl  = TextEditingController(
        text: g != null && g.targetAmount > 0
            ? g.targetAmount.toInt().toString()
            : '');
    _currentCtrl = TextEditingController(
        text: g != null && g.currentAmount > 0
            ? g.currentAmount.toInt().toString()
            : '');
    _deadline = g?.deadline ?? DateTime.now().add(const Duration(days: 365));
    _emoji    = g?.emoji ?? '🎯';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _save() async {
    final title  = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (title.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve hedef tutar zorunlu'),
            backgroundColor: AppColors.accentRed),
      );
      return;
    }

    setState(() => _saving = true);
    final current = double.tryParse(
            _currentCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        title:         title,
        targetAmount:  target,
        currentAmount: current,
        deadline:      _deadline,
        emoji:         _emoji,
        status:        current >= target ? 'completed' : 'active',
      );
      await widget.provider.updateGoal(updated);
    } else {
      final uid = widget.provider.user.id;
      final id  = 'goal_${uid}_${DateTime.now().millisecondsSinceEpoch}';
      await widget.provider.addGoal(GoalModel(
        id:            id,
        userId:        uid,
        title:         title,
        targetAmount:  target,
        currentAmount: current,
        deadline:      _deadline,
        status:        current >= target ? 'completed' : 'active',
        emoji:         _emoji,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGreen,
            surface: AppColors.bgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Hedefi Sil', style: AppTypography.headlineS),
        content: Text('Bu hedefi silmek istediğinize emin misiniz?',
            style: AppTypography.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: AppTypography.bodyM.copyWith(
                color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: AppTypography.bodyM.copyWith(
                color: AppColors.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.provider.deleteGoal(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 20),

            Row(
              children: [
                Text(_isEdit ? 'Hedefi Düzenle' : 'Yeni Hedef',
                    style: AppTypography.headlineS),
                const Spacer(),
                if (_isEdit)
                  GestureDetector(
                    onTap: _delete,
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.accentRed, size: 22),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Emoji seçici
            Text('Emoji', style: AppTypography.labelM),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (_, i) {
                  final e = _emojis[i];
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _emoji == e
                            ? AppColors.accentGreen.withValues(alpha: 0.15)
                            : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emoji == e
                              ? AppColors.accentGreen
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Center(child: Text(e,
                          style: const TextStyle(fontSize: 18))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            _field(label: 'Hedef Başlığı', controller: _titleCtrl,
                hint: 'Araba, Ev, Tatil...'),
            const SizedBox(height: 14),

            _field(label: 'Hedef Tutar (₺)', controller: _targetCtrl,
                hint: '500000', keyboard: TextInputType.number),
            const SizedBox(height: 14),

            _field(label: 'Mevcut Birikim (₺)', controller: _currentCtrl,
                hint: '0 — bugüne kadar biriktirdiğiniz',
                keyboard: TextInputType.number),
            const SizedBox(height: 14),

            // Tarih seçici
            Text('Son Tarih', style: AppTypography.labelM),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.accentGreen, size: 16),
                    const SizedBox(width: 10),
                    Text(Formatters.date(_deadline),
                        style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 15)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.bgPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.bgPrimary))
                    : Text(_isEdit ? 'Güncelle' : 'Hedef Ekle',
                        style: AppTypography.button),
              ),
            ),
          ],
        ),
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
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 13),
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

