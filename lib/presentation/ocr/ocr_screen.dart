import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/gemini_service.dart';
import '../../features/spending/presentation/viewmodel/spending_viewmodel.dart';

/// OCR Fiş / Fatura Tarama Ekranı
/// Kamera · Galeri · PDF — Gemini Vision ile doğrudan analiz
class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _picker = ImagePicker();

  // Seçili dosya — ya File (görsel) ya da PlatformFile (PDF)
  File?          _imageFile;
  PlatformFile?  _pdfFile;
  bool           _isProcessing = false;
  Map<String, dynamic>? _result;               // tek fiş sonucu
  List<Map<String, dynamic>>? _transactions;   // banka ekstresi sonucu
  Map<String, dynamic>? _bankMeta;             // banka adı, dönem vb.
  String?        _errorMessage;

  bool get _hasFile => _imageFile != null || _pdfFile != null;
  bool get _isPdf   => _pdfFile != null;
  bool get _hasResult => _result != null || (_transactions?.isNotEmpty == true);

  // ── Dosya / Görsel Seçimi ──────────────────────────────────────────────────

  Future<void> _pickCamera() async {
    try {
      final xf = await _picker.pickImage(
        source:       ImageSource.camera,
        maxWidth:     2000,
        maxHeight:    2000,
        imageQuality: 90,
      );
      if (xf == null) return;
      setState(() { _imageFile = File(xf.path); _pdfFile = null;
                    _result = null; _errorMessage = null; });
    } catch (e) {
      setState(() => _errorMessage = 'Kamera açılamadı: $e');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final xf = await _picker.pickImage(
        source:       ImageSource.gallery,
        maxWidth:     2000,
        maxHeight:    2000,
        imageQuality: 90,
      );
      if (xf == null) return;
      setState(() { _imageFile = File(xf.path); _pdfFile = null;
                    _result = null; _errorMessage = null; });
    } catch (e) {
      setState(() => _errorMessage = 'Galeri açılamadı: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type:           FileType.custom,
        allowedExtensions: ['pdf'],
        withData:       true,  // bytes direkt belleğe al
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null && file.path == null) {
        setState(() => _errorMessage = 'PDF okunamadı.');
        return;
      }
      setState(() { _pdfFile = file; _imageFile = null;
                    _result = null; _errorMessage = null; });
    } catch (e) {
      setState(() => _errorMessage = 'PDF seçilemedi: $e');
    }
  }

  // ── Gemini ile İşleme ─────────────────────────────────────────────────────

  Future<void> _processDocument() async {
    if (!_hasFile) return;
    setState(() { _isProcessing = true; _errorMessage = null; _result = null; _transactions = null; });

    try {
      final String base64Data;
      final String mediaType;

      if (_isPdf) {
        final bytes = _pdfFile!.bytes ??
            await File(_pdfFile!.path!).readAsBytes();
        base64Data = base64Encode(bytes);
        mediaType  = 'application/pdf';
      } else {
        final bytes = await _imageFile!.readAsBytes();
        base64Data  = base64Encode(bytes);
        final ext   = _imageFile!.path.split('.').last.toLowerCase();
        mediaType   = switch (ext) {
          'png'  => 'image/png',
          'webp' => 'image/webp',
          'gif'  => 'image/gif',
          _      => 'image/jpeg',
        };
      }

      const prompt = '''Analyze this document and return ONE of the following JSON formats. Output ONLY compact JSON with NO indentation, NO newlines inside strings, NO extra whitespace.

NUMBER FORMAT: Turkish documents use period (.) as thousands separator and comma (,) as decimal. Convert all amounts to positive floats. Examples: "5.803,05"→5803.05, "1.094,80"→1094.80, "200,00"→200.00

IF RECEIPT or INVOICE: {"type":"fis","merchant":"store name","total":0.0,"tax":0.0,"date":"YYYY-MM-DD","items":[{"name":"item","total":0.0}],"confidence":0.9}

IF BANK ACCOUNT STATEMENT (vadesiz/mevduat hesap ekstresi):
{"type":"banka_ekstresi","bank":"bank name","account":"account number","period":"period","transactions":[{"date":"YYYY-MM-DD","desc":"description","amt":0.0,"t":"g"}]}
Rules for bank account:
- "t":"r" ONLY for real incoming money: salary(maaş), incoming wire(havale alındı/gelen EFT), cash deposit(nakit yatırma)
- "t":"g" for ALL outgoing: purchases, outgoing wire(EFT/havale gönderildi), credit card payment(kredi kartı ödemesi/otomatik ödeme), ATM withdrawal, fees
- SKIP: opening/closing balance rows, 0.00 amount rows

IF CREDIT CARD STATEMENT (kredi kartı ekstresi):
{"type":"banka_ekstresi","bank":"bank name","account":"card number","period":"period","transactions":[{"date":"YYYY-MM-DD","desc":"description","amt":0.0,"t":"g"}]}
Rules for credit card:
- All purchases/harcamalar = "t":"g" (expense)
- SKIP payment rows entirely (ödeme, payment, minimum ödeme, son ödeme) — these are NOT income, just debt settlement
- SKIP: balance rows, limit rows, 0.00 rows, reward/puan rows, interest(faiz) rows
- Include ONLY real purchases

IF NEITHER: {"type":"hata","error":"No receipt or statement found"}''';


      final raw = await GeminiService.instance.analyzeDocument(
        base64Data: base64Data,
        mimeType:   mediaType,
        prompt:     prompt,
        maxTokens:  8192,
      );

      final parsed = _extractJson(raw);
      if (parsed == null) {
        setState(() {
          _errorMessage = raw.trim().isEmpty
              ? 'Gemini yanıt vermedi. API anahtarını ve internet bağlantısını kontrol edin.'
              : 'JSON ayrıştırma hatası.\n\nYanıt son kısmı:\n${raw.length > 300 ? raw.substring(raw.length - 200) : raw}';
          _isProcessing = false;
        });
        return;
      }

      final type = parsed['type'] as String? ?? '';

      if (type == 'hata' || parsed.containsKey('error')) {
        setState(() {
          _errorMessage = parsed['error'] as String? ?? 'Belge tanınamadı.';
          _isProcessing = false;
        });
        return;
      }

      if (type == 'banka_ekstresi') {
        final rawList = parsed['transactions'] as List?;
        if (rawList == null || rawList.isEmpty) {
          setState(() {
            _errorMessage = 'Banka ekstresinde hareket bulunamadı.';
            _isProcessing = false;
          });
          return;
        }
        // Kısa field adlarını normalize et ve kategori ekle
        final txList = rawList.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          // amt → amount, desc → description, t → transactionType
          if (!m.containsKey('amount'))          m['amount'] = m['amt'] ?? 0.0;
          if (!m.containsKey('description'))     m['description'] = m['desc'] ?? '';
          if (!m.containsKey('transactionType')) m['transactionType'] = m['t'] == 'r' ? 'gelir' : 'gider';
          m['categoryLabel'] = _inferCategory(
            m['description'] as String? ?? '',
            m['transactionType'] as String? ?? 'gider',
          );
          return m;
        }).toList();
        setState(() { _transactions = txList; _isProcessing = false; _bankMeta = parsed; });
        return;
      }

      // Fiş / Fatura
      setState(() { _result = parsed; _isProcessing = false; });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  String _inferCategory(String desc, String type) {
    if (type == 'gelir') return 'Gelir';
    final d = desc.toLowerCase();
    if (d.contains('kredi karti') || d.contains('kredi kartı') || d.contains('kart ödemesi') ||
        d.contains('kart odeme') || d.contains('otomatik odeme') || d.contains('otomatik ödeme')) { return 'Fatura'; }
    if (d.contains('petrol') || d.contains('akaryakıt') || d.contains('akaryakit') ||
        d.contains('shell') || d.contains('bp ') || d.contains('opet') ||
        d.contains('mjet') || d.contains('metro') || d.contains('taksi') ||
        d.contains('uber') || d.contains('bilet') || d.contains('otobus') ||
        d.contains('otobüs')) { return 'Ulaşım'; }
    if (d.contains('cafe') || d.contains('pizza') || d.contains('burger') ||
        d.contains('restaurant') || d.contains('restoran') || d.contains('yemek') ||
        d.contains('pastane') || d.contains('çiğköfte') || d.contains('cigkofte') ||
        d.contains('chicken') || d.contains('yolda') || d.contains('döner') ||
        d.contains('doner') || d.contains('kahve') || d.contains('coffee')) { return 'Yeme-İçme'; }
    if (d.contains('market') || d.contains('gıda') || d.contains('gida') ||
        d.contains('migros') || d.contains('a101') || d.contains('bim ') ||
        d.contains('carrefour') || d.contains('şok ') || d.contains('unlu') ||
        d.contains('kuruyem') || d.contains('kozmetik') || d.contains('çiçek') ||
        d.contains('kral') || d.contains('mavi köşe')) { return 'Alışveriş'; }
    if (d.contains('netflix') || d.contains('apple') || d.contains('google') ||
        d.contains('youtube') || d.contains('hbomax') || d.contains('todtv') ||
        d.contains('steam') || d.contains('fatura') || d.contains('iyzico') ||
        d.contains('spotify') || d.contains('abonelik') || d.contains('doğalgaz') ||
        d.contains('elektrik') || d.contains('su fatura') || d.contains('internet')) { return 'Fatura'; }
    if (d.contains('eczane') || d.contains('hastane') || d.contains('doktor') ||
        d.contains('sağlık') || d.contains('saglik') || d.contains('ilaç') ||
        d.contains('ilac') || d.contains('klinik') || d.contains('diş')) { return 'Sağlık'; }
    if (d.contains('eft') || d.contains('havale') || d.contains('transfer') ||
        d.contains('para gönder') || d.contains('para gonder')) { return 'Transfer'; }
    return 'Diğer';
  }

  Map<String, dynamic>? _extractJson(String raw) {
    if (raw.trim().isEmpty) return null;

    // responseMimeType:'application/json' ile genelde temiz gelir — direkt dene
    try {
      return jsonDecode(raw.trim()) as Map<String, dynamic>;
    } catch (_) {}

    // Markdown veya ön/arka metin varsa temizle
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Brace balancing: açılış { bulup kapanana kadar say
    final start = cleaned.indexOf('{');
    if (start == -1) return null;

    int depth = 0;
    int end = -1;
    for (int i = start; i < cleaned.length; i++) {
      final c = cleaned[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) { end = i; break; }
      }
    }
    if (end == -1) return null;

    try {
      return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Harcama Kaydet ────────────────────────────────────────────────────────

  Future<void> _saveAsTransaction() async {
    if (_result == null) return;
    final total = (_result!['total'] as num?)?.toDouble() ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tutar okunamadı, lütfen manuel girin.'),
        backgroundColor: AppColors.accentAmber,
      ));
      return;
    }

    final vm = context.read<SpendingViewModel>();
    await vm.addTransaction(
      amount:   total,
      category: _result!['categoryLabel'] as String? ?? 'Diğer',
      type:     'gider',
      source:   'ocr',
      note:     _result!['merchant'] as String?,
      date:     DateTime.tryParse(_result!['date'] ?? '') ?? DateTime.now(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Harcama kaydedildi ✓'),
      backgroundColor: AppColors.accentGreen,
    ));
    Navigator.pop(context);
  }

  Future<void> _saveAllTransactions() async {
    if (_transactions == null || _transactions!.isEmpty) return;

    setState(() => _isProcessing = true);

    final vm = context.read<SpendingViewModel>();

    // Geçerli işlemleri filtrele
    final validTx = _transactions!.where((tx) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      return amount > 0;
    }).toList();

    // Tüm yazmaları PARALLEL yap, her birinde reload=false
    final results = await Future.wait(
      validTx.map((tx) async {
        try {
          final txType = tx['transactionType'] as String? ?? 'gider';
          return await vm.addTransaction(
            amount:   (tx['amount'] as num).toDouble(),
            category: tx['categoryLabel'] as String? ?? 'Diğer',
            type:     txType == 'gelir' ? 'income' : 'expense',
            source:   'ocr',
            note:     tx['description'] as String?,
            date:     DateTime.tryParse(tx['date'] as String? ?? '') ?? DateTime.now(),
            reload:   false,  // Her işlemden sonra yenileme — en sonda bir kez yapılacak
          );
        } catch (_) {
          return false;
        }
      }),
    );

    // AppProvider real-time stream sayesinde otomatik güncellenir

    // İşlemlerin tarih aralığını bul ve o dönemi yükle
    final dates = validTx
        .map((tx) => DateTime.tryParse(tx['date'] as String? ?? ''))
        .whereType<DateTime>()
        .toList();
    if (dates.isNotEmpty) {
      dates.sort();
      await vm.loadPeriod(
        DateTime(dates.first.year, dates.first.month, 1),
        DateTime(dates.last.year, dates.last.month + 1, 1),
      );
    } else {
      await vm.loadCurrentMonth();
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final saved  = results.where((r) => r).length;
    final failed = results.where((r) => !r).length;

    if (saved == 0) {
      setState(() {
        _errorMessage = 'Hiçbir işlem kaydedilemedi. Firestore bağlantısını kontrol edin.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed > 0
          ? '$saved kaydedildi, $failed başarısız'
          : '$saved hareket kaydedildi ✓'),
      backgroundColor: failed > 0 ? AppColors.accentAmber : AppColors.accentGreen,
    ));
    Navigator.pop(context);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: Text('Belge Tara', style: AppTypography.headlineS),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Önizleme
              _PreviewArea(
                imageFile:    _imageFile,
                pdfFile:      _pdfFile,
                isProcessing: _isProcessing,
              ),
              const SizedBox(height: 16),

              // Kaynak butonları
              Row(
                children: [
                  Expanded(child: _SourceBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    onTap: _pickCamera,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _SourceBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: _pickGallery,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _SourceBtn(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onTap: _pickPdf,
                    accent: AppColors.accentAmber,
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // OCR başlat
              if (_hasFile && !_hasResult)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processDocument,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.document_scanner_outlined, size: 20),
                    label: Text(
                      _isProcessing ? 'Gemini okuyor...' : 'Belgeyi Oku',
                      style: AppTypography.labelM.copyWith(
                        color: Colors.black, fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),

              // Hata
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],

              // Fiş / Fatura sonucu
              if (_result != null) ...[
                const SizedBox(height: 20),
                _ResultCard(
                  result:  _result!,
                  onSave:  _saveAsTransaction,
                  onRetry: () => setState(() { _result = null; _errorMessage = null; }),
                ),
              ],

              // Banka ekstresi sonucu
              if (_transactions != null) ...[
                const SizedBox(height: 20),
                _BankStatementCard(
                  transactions: _transactions!,
                  meta:         _bankMeta ?? {},
                  onSaveAll:    _saveAllTransactions,
                  onRetry:      () => setState(() { _transactions = null; _bankMeta = null; _errorMessage = null; }),
                ),
              ],

              // İpuçları
              if (!_hasFile) ...[
                const SizedBox(height: 32),
                const _TipsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Önizleme ──────────────────────────────────────────────────────────────────

class _PreviewArea extends StatelessWidget {
  final File?         imageFile;
  final PlatformFile? pdfFile;
  final bool          isProcessing;

  const _PreviewArea({
    required this.imageFile,
    required this.pdfFile,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: imageFile != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(imageFile!, fit: BoxFit.cover),
                ),
                if (isProcessing) const _ScanOverlay(),
              ],
            )
          : pdfFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: AppColors.accentAmber, size: 52),
                        const SizedBox(height: 10),
                        Text(pdfFile!.name,
                            style: AppTypography.bodyS,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          _fileSize(pdfFile!.size),
                          style: AppTypography.labelS,
                        ),
                      ],
                    ),
                    if (isProcessing) const _ScanOverlay(),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.textDisabled, size: 48),
                    const SizedBox(height: 10),
                    Text('Fiş, fatura veya banka ekstresi seçin',
                        style: AppTypography.bodyM),
                  ],
                ),
    );
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accentGreen, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Gemini analiz ediyor...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Kaynak Butonu ─────────────────────────────────────────────────────────────

class _SourceBtn extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  final Color      accent;

  const _SourceBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelS),
          ],
        ),
      ),
    );
  }
}

// ── Hata Banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.accentRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTypography.bodyS.copyWith(
              color: AppColors.accentRed, height: 1.4,
            )),
          ),
        ],
      ),
    );
  }
}

// ── Sonuç Kartı ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ResultCard({
    required this.result,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final total      = (result['total'] as num?)?.toDouble() ?? 0;
    final merchant   = result['merchant'] as String? ?? 'Bilinmeyen';
    final category   = result['categoryLabel'] as String? ?? 'Diğer';
    final date       = result['date'] as String? ?? '';
    final tax        = (result['tax'] as num?)?.toDouble() ?? 0;
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0;
    final items      = (result['items'] as List?)?.cast<Map>() ?? [];
    final isHighConf = confidence >= 0.7;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.accentGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiş Okundu', style: AppTypography.headlineS),
                  Text(
                    'Güven: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: AppTypography.labelS.copyWith(
                      color: isHighConf
                          ? AppColors.accentGreen
                          : AppColors.accentAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          _row('Mağaza',    merchant),
          _row('Kategori',  category),
          if (date.isNotEmpty) _row('Tarih', date),
          _row('Toplam',    '${total.toStringAsFixed(2)} ₺'),
          if (tax > 0) _row('KDV',  '${tax.toStringAsFixed(2)} ₺'),

          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Kalemler', style: AppTypography.labelS.copyWith(
              color: AppColors.textSecondary, letterSpacing: 0.8,
            )),
            const SizedBox(height: 6),
            ...items.take(6).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['name'] as String? ?? '',
                      style: AppTypography.bodyS,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${((item['total'] as num?) ?? 0).toStringAsFixed(2)} ₺',
                    style: GoogleFonts.dmMono(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tekrar',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.textSecondary,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Harcama Kaydet',
                      style: AppTypography.labelS.copyWith(
                        color: Colors.black, fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Text(label, style: AppTypography.bodyS.copyWith(
          color: AppColors.textSecondary,
        )),
        const Spacer(),
        Text(value, style: GoogleFonts.dmMono(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        )),
      ],
    ),
  );
}

// ── Banka Ekstresi Kartı ───────────────────────────────────────────────────────

class _BankStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Map<String, dynamic>       meta;
  final VoidCallback               onSaveAll;
  final VoidCallback               onRetry;

  const _BankStatementCard({
    required this.transactions,
    required this.meta,
    required this.onSaveAll,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bank   = meta['bank']   as String? ?? 'Banka';
    final period = meta['period'] as String? ?? '';

    final gelirCount = transactions.where((t) => t['transactionType'] == 'gelir').length;
    final giderCount = transactions.length - gelirCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    color: AppColors.accentGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Banka Ekstresi Okundu', style: AppTypography.headlineS),
                    Text(
                      bank + (period.isNotEmpty ? ' · $period' : ''),
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Özet
          Row(
            children: [
              _StatChip(label: '${transactions.length} hareket',
                  color: AppColors.accentGreen),
              const SizedBox(width: 8),
              _StatChip(label: '$giderCount gider',
                  color: AppColors.accentRed),
              const SizedBox(width: 8),
              _StatChip(label: '$gelirCount gelir',
                  color: AppColors.accentAmber),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          // Hareket listesi (max 15 göster)
          ...transactions.take(15).map((tx) => _TxRow(tx: tx)),
          if (transactions.length > 15)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${transactions.length - 15} hareket daha',
                style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary),
              ),
            ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tekrar',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSaveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Tümünü Kaydet',
                      style: AppTypography.labelS.copyWith(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTypography.labelS.copyWith(color: color, fontSize: 11)),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isGelir = tx['transactionType'] == 'gelir';
    final amount  = (tx['amount'] as num?)?.toDouble() ?? 0;
    final date    = tx['date'] as String? ?? '';
    final desc    = tx['description'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: (isGelir ? AppColors.accentGreen : AppColors.accentRed)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isGelir ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: isGelir ? AppColors.accentGreen : AppColors.accentRed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: AppTypography.bodyS,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (date.isNotEmpty)
                  Text(date, style: AppTypography.labelS.copyWith(
                      color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '${isGelir ? '+' : '-'}${amount.toStringAsFixed(2)} ₺',
            style: GoogleFonts.dmMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isGelir ? AppColors.accentGreen : AppColors.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ── İpuçları ──────────────────────────────────────────────────────────────────

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (Icons.camera_alt_outlined,         'Net fotoğraf çekin',
       'Düz yüzey, iyi ışık, tüm fiş görünür olsun'),
      (Icons.picture_as_pdf_outlined,     'Banka ekstresi veya fatura',
       'PDF ekstreler otomatik algılanır, tüm hareketler listelenir'),
      (Icons.wb_sunny_outlined,           'Aydınlık ortam',
       'Gölge ve yansımalardan kaçının'),
      (Icons.crop_free_outlined,          'Tüm belge görünsün',
       'Kenarlar kesilmesin, metin okunabilir olsun'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İpuçları', style: AppTypography.headlineS),
        const SizedBox(height: 12),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(t.$1, color: AppColors.accentAmber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$2, style: AppTypography.labelS.copyWith(
                      color: AppColors.textPrimary,
                    )),
                    Text(t.$3, style: AppTypography.bodyS),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
