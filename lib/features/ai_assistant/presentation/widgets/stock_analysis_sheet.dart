import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/assistant_context.dart';
import '../assistant_context_builder.dart';
import '../viewmodel/ai_assistant_viewmodel.dart';

/// Bir varlık için derin analiz sayfası.
///
/// Analiz; canlı fiyat, gün içi aralık, hacim, o varlıkla ilgili haber akışı,
/// kullanıcının pozisyonu ve portföy ağırlığı birlikte değerlendirilerek
/// üretilir (bkz. `AssistantPrompts.stockAnalysis`).
Future<void> showStockAnalysisSheet(
  BuildContext context, {
  required String symbol,
  required String companyName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockAnalysisSheet(
      symbol: symbol,
      companyName: companyName,
      // Sayfa açılırken bağlam çağıran ekrandan alınır — sheet'in kendi
      // context'i sağlayıcı ağacının dışında kalabiliyor.
      assistantContext: AssistantContextBuilder.fromContext(context),
    ),
  );
}

class _StockAnalysisSheet extends StatefulWidget {
  final String symbol;
  final String companyName;
  final AssistantContext assistantContext;

  const _StockAnalysisSheet({
    required this.symbol,
    required this.companyName,
    required this.assistantContext,
  });

  @override
  State<_StockAnalysisSheet> createState() => _StockAnalysisSheetState();
}

class _StockAnalysisSheetState extends State<_StockAnalysisSheet> {
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final vm = getIt<AiAssistantViewModel>();
    try {
      final text = await vm.analyzeStock(
        symbol: widget.symbol,
        companyName: widget.companyName,
        context: widget.assistantContext,
      );
      if (!mounted) return;
      setState(() {
        _result = text;
        _error = text == null ? 'Analiz alınamadı.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgVoid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🔬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.symbol,
                            style: GoogleFonts.fraunces(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(widget.companyName,
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            Expanded(child: _body(scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController controller) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.accentRed, size: 32),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _error = null;
                    _result = null;
                  });
                  _run();
                },
                child: Text('Tekrar dene',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGreen)),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentGreen),
            ),
            const SizedBox(height: 14),
            Text('Fiyat, haber ve pozisyonun birlikte inceleniyor…',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 12.5, color: Colors.white54)),
          ],
        ),
      );
    }

    return Markdown(
      controller: controller,
      data: _result!,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.outfit(
            fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.85)),
        h3: GoogleFonts.fraunces(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        h2: GoogleFonts.fraunces(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        strong: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        listBullet: GoogleFonts.outfit(
            fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
        blockquoteDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// "Liqra'ya analiz ettir" düğmesi — varlık kartlarına eklenir.
class AnalyzeButton extends StatelessWidget {
  final String symbol;
  final String companyName;
  final bool compact;

  const AnalyzeButton({
    super.key,
    required this.symbol,
    required this.companyName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showStockAnalysisSheet(
        context,
        symbol: symbol,
        companyName: companyName,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12, vertical: compact ? 4 : 7),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: compact ? 11 : 13, color: AppColors.accentGreen),
            SizedBox(width: compact ? 4 : 6),
            Text(
              compact ? 'Analiz' : "Liqra'ya analiz ettir",
              style: GoogleFonts.outfit(
                fontSize: compact ? 11 : 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
