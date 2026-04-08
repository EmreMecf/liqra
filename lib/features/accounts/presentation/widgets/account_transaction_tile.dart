import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/account_transaction_entity.dart';

class AccountTransactionTile extends StatelessWidget {
  final AccountTransactionEntity tx;
  final VoidCallback? onDelete;

  const AccountTransactionTile({super.key, required this.tx, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? const Color(0xFF00C896) : const Color(0xFFFF4757);
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final dateFmt = DateFormat('d MMM', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Kategori ikonu
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                _categoryEmoji(tx.category),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Açıklama + tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tx.description,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tx.isInstallment)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4B84A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFE4B84A).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${tx.installmentNumber}/${tx.installmentCount}',
                          style: GoogleFonts.dmMono(
                            fontSize: 9,
                            color: const Color(0xFFE4B84A),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${dateFmt.format(tx.date)} · ${tx.category}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Tutar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${fmt.format(tx.amount)}',
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close,
                      size: 14, color: Colors.white.withValues(alpha: 0.2)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'market':       return '🛒';
      case 'yemeicme':
      case 'yeme-içme':   return '🍽️';
      case 'eglence':
      case 'eğlence':     return '🎮';
      case 'fatura':       return '📄';
      case 'ulasim':
      case 'ulaşım':      return '🚗';
      case 'saglik':
      case 'sağlık':      return '🏥';
      case 'giyim':        return '👕';
      case 'egitim':
      case 'eğitim':      return '📚';
      case 'teknoloji':    return '💻';
      case 'gelir':
      case 'income':       return '💰';
      default:             return '💳';
    }
  }
}
