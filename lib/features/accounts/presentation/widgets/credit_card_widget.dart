
import 'package:flutter/material.dart';
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
            // Kart yüzeyi
            _CardFace(card: card, bankColor: bankColor, onDelete: onDelete),

            const SizedBox(height: 10),

            // Limit kullanım + ekstre bilgisi
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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF1A2235), bankColor, 0.25)!,
            Color.lerp(const Color(0xFF0C1120), bankColor, 0.12)!,
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
      child: Stack(
        children: [
          // Chip efekti
          Positioned(
            top: 22,
            left: 22,
            child: _ChipWidget(color: bankColor),
          ),

          // Menü butonu
          if (onDelete != null)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.4), size: 18),
              ),
            ),

          // Kart numarası
          Positioned(
            top: 72,
            left: 22,
            right: 22,
            child: Text(
              card.maskedCardNumber != null
                  ? '•••• •••• •••• ${card.maskedCardNumber}'
                  : '•••• •••• •••• ••••',
              style: GoogleFonts.dmMono(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 2,
              ),
            ),
          ),

          // Alt: kart adı + banka
          Positioned(
            bottom: 18,
            left: 22,
            right: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Row(
                  children: [
                    Text(card.bank.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
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
          ),

          // Kredi kartı etiketi
          Positioned(
            top: 14,
            left: 65,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        ? const Color(0xFFFF4757)
        : card.isDueSoon
            ? const Color(0xFFE4B84A)
            : Colors.white.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Limit çubuğu
          Row(
            children: [
              Text(
                'Kullanılan',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
              ),
              const Spacer(),
              Text(
                '${fmt.format(card.usedAmount)} / ${fmt.format(card.creditLimit)}',
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
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
                usage > 0.8
                    ? const Color(0xFFFF4757)
                    : usage > 0.5
                        ? const Color(0xFFE4B84A)
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
                label: card.isOverdue
                    ? 'Gecikmiş!'
                    : '${card.daysUntilDue} gün',
                value: card.isOverdue ? 'Ödenmedi' : 'Son Ödeme',
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
  final Color color;
  const _ChipWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 28),
      painter: _ChipPainter(color: color),
    );
  }
}

class _ChipPainter extends CustomPainter {
  final Color color;
  const _ChipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, strokePaint);

    // İç çizgiler
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 0.7;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), linePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
