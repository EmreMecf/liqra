import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_provider.dart';
import '../widgets/app_card.dart';

/// KVKK — Kişisel Verilerin Korunması Kanunu
/// Veri dışa aktarma + hesap silme ekranı
class KvkkScreen extends StatefulWidget {
  const KvkkScreen({super.key});

  @override
  State<KvkkScreen> createState() => _KvkkScreenState();
}

class _KvkkScreenState extends State<KvkkScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  // ── Veri Dışa Aktarma ────────────────────────────────────────────────────
  Future<void> _exportData(BuildContext context) async {
    final provider = context.read<AppProvider>();
    setState(() => _isExporting = true);

    try {
      // İşlemleri CSV satırlarına dönüştür
      final buffer = StringBuffer();

      // Başlık satırı
      buffer.writeln('Tarih,Tür,Kategori,Tutar,Kaynak,Not');

      // Harcamalar
      for (final tx in provider.transactions) {
        final date = '${tx.date.year}-'
            '${tx.date.month.toString().padLeft(2, '0')}-'
            '${tx.date.day.toString().padLeft(2, '0')}';
        final type = tx.isExpense ? 'Gider' : 'Gelir';
        final amount = tx.amount.toStringAsFixed(2);
        final category = _csvEscape(tx.category.label);
        final source = _csvEscape(tx.source);
        final note = _csvEscape(tx.note ?? '');
        buffer.writeln('$date,$type,$category,$amount,$source,$note');
      }

      // CSV içeriği hazır — base64 olarak göster
      final csvContent = buffer.toString();
      final base64Content = base64Encode(utf8.encode(csvContent));

      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      await showDialog<void>(
        context: context,
        builder: (_) => _ExportDialog(
          csvPreview: csvContent,
          base64Content: base64Content,
          transactionCount: provider.transactions.length,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Hesap Silme ──────────────────────────────────────────────────────────
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (confirmed == true && context.mounted) {
      setState(() => _isDeleting = true);
      // Simüle: gerçek uygulamada API çağrısı yapılır
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _isDeleting = false);
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Hesabınız silme kuyruğuna alındı. 30 gün içinde tamamlanacak.',
              style: AppTypography.bodyS),
          backgroundColor: AppColors.accentRed,
          duration: const Duration(seconds: 5),
        ),
      );
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Veri & Gizlilik', style: AppTypography.headlineS),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── KVKK hakları bilgilendirme ────────────────────────────────
          _SectionHeader(
            icon: Icons.shield_outlined,
            iconColor: AppColors.accentBlue,
            title: 'KVKK Kapsamındaki Haklarınız',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _RightRow(
                  icon: Icons.info_outline,
                  title: 'Bilgi Edinme Hakkı',
                  description:
                      'Kişisel verilerinizin işlenip işlenmediğini ve hangi amaçla '
                      'kullanıldığını öğrenebilirsiniz.',
                ),
                const _Divider(),
                _RightRow(
                  icon: Icons.download_outlined,
                  title: 'Veri Taşınabilirliği',
                  description:
                      'İşlenen kişisel verilerinizi yapılandırılmış ve makine tarafından '
                      'okunabilir formatta (CSV) talep edebilirsiniz.',
                ),
                const _Divider(),
                _RightRow(
                  icon: Icons.edit_outlined,
                  title: 'Düzeltme Hakkı',
                  description:
                      'Eksik veya yanlış kişisel verilerinizin düzeltilmesini '
                      'talep edebilirsiniz.',
                ),
                const _Divider(),
                _RightRow(
                  icon: Icons.delete_outline,
                  title: 'Silme Hakkı ("Unutulma")',
                  description:
                      'Kişisel verilerinizin silinmesini veya yok edilmesini '
                      'talep edebilirsiniz. Hesap silme 30 gün içinde tamamlanır.',
                ),
                const _Divider(),
                _RightRow(
                  icon: Icons.block_outlined,
                  title: 'İşlemeye İtiraz',
                  description:
                      'Verilerinizin belirli amaçlarla işlenmesine itiraz '
                      'edebilirsiniz.',
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // ── Veri Dışa Aktarma ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.download_outlined,
            iconColor: AppColors.accentGreen,
            title: 'Verilerimi İndir',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tüm işlem geçmişinizi, kategori dağılımınızı ve mali özetinizi '
                  'CSV formatında dışa aktarabilirsiniz.',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoChip(
                  label: 'Biçim: CSV (Excel uyumlu)',
                  icon: Icons.table_chart_outlined,
                ),
                const SizedBox(height: 8),
                _InfoChip(
                  label: 'Şifreleme: yok (yerel indirme)',
                  icon: Icons.lock_open_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _exportData(context),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bgPrimary,
                            ),
                          )
                        : const Icon(Icons.download_outlined, size: 18),
                    label: Text(
                      _isExporting ? 'Hazırlanıyor...' : 'Verilerimi Dışa Aktar (CSV)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: AppColors.bgPrimary,
                      disabledBackgroundColor: AppColors.accentGreen.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      textStyle: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // ── İletişim ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.mail_outline,
            iconColor: AppColors.accentAmber,
            title: 'KVKK Başvurusu',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KVKK kapsamındaki diğer talepleriniz için yazılı başvuru yapabilirsiniz.',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'kvkk@finansasistani.com',
                ),
                const SizedBox(height: 10),
                _ContactRow(
                  icon: Icons.language_outlined,
                  label: 'www.finansasistani.com/kvkk',
                ),
                const SizedBox(height: 10),
                _ContactRow(
                  icon: Icons.access_time_outlined,
                  label: 'Yanıt süresi: 30 iş günü',
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // ── Tehlikeli bölge ───────────────────────────────────────────
          _SectionHeader(
            icon: Icons.warning_amber_outlined,
            iconColor: AppColors.accentRed,
            title: 'Tehlikeli Bölge',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_forever_outlined,
                          color: AppColors.accentRed, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hesabı Kalıcı Olarak Sil',
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            'Tüm veriler 30 gün içinde silinir. Bu işlem geri alınamaz.',
                            style: AppTypography.labelS,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting
                        ? null
                        : () => _showDeleteConfirmation(context),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentRed,
                            ),
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text(_isDeleting ? 'İşleniyor...' : 'Hesabı Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: const BorderSide(color: AppColors.accentRed, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Liqra — KVKK Uyumlu\n6698 sayılı Kişisel Verilerin Korunması Kanunu',
              style: AppTypography.labelS.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Dışa Aktarma Dialog ─────────────────────────────────────────────────────
class _ExportDialog extends StatelessWidget {
  final String csvPreview;
  final String base64Content;
  final int transactionCount;

  const _ExportDialog({
    required this.csvPreview,
    required this.base64Content,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    // İlk 5 satırı önizleme olarak göster
    final previewLines = csvPreview.split('\n').take(6).join('\n');

    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.accentGreen, size: 22),
          const SizedBox(width: 8),
          Text('CSV Hazır', style: AppTypography.headlineS),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$transactionCount işlem dışa aktarıldı.',
            style: AppTypography.bodyM.copyWith(color: AppColors.accentGreen),
          ),
          const SizedBox(height: 16),
          Text('Önizleme:', style: AppTypography.labelS),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              previewLines,
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gerçek uygulamada dosya cihazınıza kaydedilir. '
            'Bu demo sürümde CSV içeriği bellekte üretildi.',
            style: AppTypography.labelS.copyWith(height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Kapat', style: AppTypography.bodyM.copyWith(
            color: AppColors.accentGreen,
          )),
        ),
      ],
    );
  }
}

// ── Hesap Silme Onay Dialog ──────────────────────────────────────────────────
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _understood = false;
  final _controller = TextEditingController();
  bool get _canDelete => _understood && _controller.text.trim() == 'SİL';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.accentRed, size: 22),
          const SizedBox(width: 8),
          Text('Hesabı Sil', style: AppTypography.headlineS.copyWith(
            color: AppColors.accentRed,
          )),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uyarı listesi
          _WarningItem('Tüm işlem geçmişiniz silinir'),
          _WarningItem('Portföy verileriniz silinir'),
          _WarningItem('AI sohbet geçmişiniz silinir'),
          _WarningItem('Bu işlem 30 gün içinde tamamlanır'),
          _WarningItem('30 gün içinde iptal edebilirsiniz'),
          const SizedBox(height: 16),

          // Onay kutusu
          GestureDetector(
            onTap: () => setState(() => _understood = !_understood),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _understood,
                  onChanged: (v) => setState(() => _understood = v ?? false),
                  activeColor: AppColors.accentRed,
                  side: const BorderSide(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu sonuçları anlıyorum ve hesabımın silinmesini istiyorum.',
                    style: AppTypography.bodyS.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Onay metni girişi
          Text(
            'Onaylamak için "SİL" yazın:',
            style: AppTypography.labelS,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accentRed),
              ),
              hintText: 'SİL',
              hintStyle: AppTypography.bodyM.copyWith(
                color: AppColors.textDisabled,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Vazgeç', style: AppTypography.bodyM.copyWith(
            color: AppColors.textSecondary,
          )),
        ),
        TextButton(
          onPressed: _canDelete
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(
            'Hesabı Sil',
            style: AppTypography.bodyM.copyWith(
              color: _canDelete
                  ? AppColors.accentRed
                  : AppColors.textDisabled,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Yardımcı widget'lar ──────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.headlineS),
      ],
    );
  }
}

class _RightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _RightRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyM.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodyS.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.borderSubtle, height: 1);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelS),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentAmber, size: 16),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodyS.copyWith(
          color: AppColors.textPrimary,
        )),
      ],
    );
  }
}

class _WarningItem extends StatelessWidget {
  final String text;
  const _WarningItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, color: AppColors.accentRed, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.bodyS),
          ),
        ],
      ),
    );
  }
}
