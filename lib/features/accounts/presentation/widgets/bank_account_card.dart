import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/financial_account_entity.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccountEntity account;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BankAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bankColor = account.bank.primaryColor;
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A2235),
              Color.lerp(const Color(0xFF0F1922), bankColor.withValues(alpha: 0.15), 0.6)!,
            ],
          ),
          border: Border.all(color: bankColor.withValues(alpha: 0.25), width: 1),
        ),
        child: Stack(
          children: [
            // Glow effect
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [bankColor.withValues(alpha: 0.12), Colors.transparent],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banka adı + menü
                  Row(
                    children: [
                      Text(account.bank.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          account.bank.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(Icons.more_horiz,
                              color: Colors.white.withValues(alpha: 0.4), size: 18),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Bakiye
                  Text(
                    fmt.format(account.balance),
                    style: GoogleFonts.dmMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Hesap adı + IBAN
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.name,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      if (account.iban != null)
                        Text(
                          'TR ···${account.iban!.replaceAll(' ', '').substring(account.iban!.replaceAll(' ', '').length - 4)}',
                          style: GoogleFonts.dmMono(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Banka hesabı etiketi
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bankColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Banka',
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
      ),
    );
  }
}
