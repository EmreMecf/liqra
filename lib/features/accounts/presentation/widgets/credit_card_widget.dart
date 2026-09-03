
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/financial_account_entity.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCardEntity card;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bankColor = card.bank.primaryColor;
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 300,
        child: Column(
          children: [
            // Kart yüzeyi ve bilgi paneli — aralarında boşluk yok.
            // Eskiden 10 piksellik boşluk vardı ve ikisi ayrı kart gibi
            // okunuyordu; oysa aynı kartın iki yüzü.
            _CardFace(card: card, bankColor: bankColor, onDelete: onDelete),
            _CardInfo(card: card, bankColor: bankColor, fmt: fmt),
          ],
        ),
      ),
    );
  }
}

// ── Fiziksel kart görünümü ─────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final CreditCardEntity card;
  final Color bankColor;
  final VoidCallback? onDelete;

  const _CardFace({required this.card, required this.bankColor, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.bgCard2, bankColor, 0.25)!,
            Color.lerp(AppColors.bgVoid, bankColor, 0.12)!,
            const Color(0xFF080C16),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: bankColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: bankColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Mutlak konumlandırma yerine dikey akış: kartın ortasında 54 piksellik
      // bir boşluk kalıyordu ve kart yarım basılmış gibi görünüyordu.
      // Boşluğa kullanıcının asıl merak ettiği rakam kondu: toplam borç.
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ChipWidget(),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bankColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Kredi',
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    color: bankColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.4), size: 18),
                ),
            ],
          ),

          const Spacer(),

          // Toplam borç — kartın kahramanı
          Text(
            'TOPLAM BORÇ',
            style: GoogleFonts.dmMono(
              fontSize: 8.5,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            NumberFormat.currency(
                    locale: 'tr_TR', symbol: '₺', decimalDigits: 0)
                .format(card.usedAmount),
            style: GoogleFonts.dmMono(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            card.maskedCardNumber != null
                ? '•••• ${card.maskedCardNumber}'
                : '•••• ••••',
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 1.5,
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: Text(
                  card.name,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card.bank.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Limit bilgi paneli ─────────────────────────────────────────────────────

class _CardInfo extends StatelessWidget {
  final CreditCardEntity card;
  final Color bankColor;
  final NumberFormat fmt;

  const _CardInfo({required this.card, required this.bankColor, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final usage = card.usagePercent;
    final dueColor = card.isOverdue
        ? AppColors.accentRed
        : card.isDueSoon
            ? AppColors.accentAmber
            : Colors.white.withValues(alpha: 0.5);

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Limit çubuğu
          Row(
            children: [
              Text(
                card.isOverLimit ? 'Limit aşıldı' : 'Kullanılan',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: card.isOverLimit
                        ? AppColors.accentRed
                        : Colors.white.withValues(alpha: 0.4)),
              ),
              const Spacer(),
              Text(
                '${fmt.format(card.usedAmount)} / ${fmt.format(card.creditLimit)}',
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: card.isOverLimit
                      ? AppColors.accentRed
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                card.isOverLimit || usage > 0.8
                    ? AppColors.accentRed
                    : usage > 0.5
                        ? AppColors.accentAmber
                        : bankColor,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Ekstre borcu + Son ödeme
          Row(
            children: [
              _InfoChip(
                label: 'Ekstre',
                value: fmt.format(card.statementBalance),
                color: bankColor,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                // isOverdue artık gerçek gecikmeyi gösterir; eskiden bu dal
                // hiçbir zaman çalışmıyordu.
                label: card.isOverdue
                    ? '${card.daysPastDue} gün geçti'
                    : card.daysUntilDue == 0
                        ? 'Bugün'
                        : '${card.daysUntilDue} gün',
                value: card.isOverdue ? 'Gecikti' : 'Son Ödeme',
                color: dueColor,
                reversed: true,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Asgari',
                value: fmt.format(card.minimumPayment),
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool reversed;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reversed ? value : label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Text(
            reversed ? label : value,
            style: GoogleFonts.dmMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip widget ────────────────────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  const _ChipWidget();

  @override
  Widget build(BuildContext context) => const CustomPaint(
        size: Size(34, 26),
        painter: _ChipPainter(),
      );
}

/// Kart çipi — metalik altın, kontak pedleri görünür.
///
/// Eskiden bankanın markası %50 saydamlıkla düz doldurulur, iç çizgiler %25
/// saydamlıkta çizilirdi: sonuç, kartın sol üstünde duran **düz renkli bir
/// blok**tu ve bozuk görsel yer tutucusuna benziyordu. Çip artık her bankada
/// aynı altın tonunda — bankayı zaten kartın degrade rengi anlatıyor.
class _ChipPainter extends CustomPainter {
  const _ChipPainter();

  static const _light = Color(0xFFE8CB86);
  static const _dark  = Color(0xFF9C7C34);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Metalik gövde — köşeden köşeye degrade
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_light, _dark],
        ).createShader(rect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = _dark.withValues(alpha: 0.8),
    );

    // Kontak pedleri — gerçek çipteki bölünmüş yüzey
    final line = Paint()
      ..color = _dark.withValues(alpha: 0.85)
      ..strokeWidth = 0.9;

    final midY = size.height / 2;
    final inset = size.width * 0.22;

    // Yatay orta hat, kenarlara değmeden
    canvas.drawLine(Offset(inset, midY), Offset(size.width - inset, midY), line);
    // İki dikey ayraç
    canvas.drawLine(Offset(inset, 0), Offset(inset, size.height), line);
    canvas.drawLine(
        Offset(size.width - inset, 0), Offset(size.width - inset, size.height), line);
    // Orta pedin üst/alt kenarları
    final padTop = size.height * 0.28;
    canvas.drawLine(
        Offset(inset, padTop), Offset(size.width - inset, padTop), line);
    canvas.drawLine(Offset(inset, size.height - padTop),
        Offset(size.width - inset, size.height - padTop), line);
  }

  @override
  bool shouldRepaint(_) => false;
}
