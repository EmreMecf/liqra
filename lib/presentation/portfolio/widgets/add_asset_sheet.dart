import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/portfolio/data/datasources/tefas_datasource.dart';
import '../../../features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';

/// Popüler BIST hisseleri (Firestore'dan fiyat alınır)
const _popularBist = [
  ('GARAN', 'Garanti BBVA'),     ('BIMAS', 'BİM Mağazalar'),
  ('THYAO', 'Türk Hava Yolları'),('AKBNK', 'Akbank'),
  ('ASELS', 'Aselsan'),          ('EREGL', 'Ereğli Demir'),
  ('SISE',  'Şişecam'),          ('KCHOL', 'Koç Holding'),
  ('ISCTR', 'İş Bankası C'),     ('SAHOL', 'Sabancı Holding'),
  ('TCELL', 'Turkcell'),         ('FROTO', 'Ford Otomotiv'),
  ('PGSUS', 'Pegasus'),          ('YKBNK', 'Yapı Kredi'),
  ('TUPRS', 'Tüpraş'),
];

/// Varlık Ekle Bottom Sheet
/// Fon tipinde: TEFAS fon arama ve otomatik fiyat doldurma
/// Hisse tipinde: BIST hisse seçimi + Firestore fiyat çekimi
class AddAssetSheet extends StatefulWidget {
  final String? initialType;
  const AddAssetSheet({super.key, this.initialType});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _qtyCtrl   = TextEditingController();
  final _priceCtrl = TextEditingController();

  // TEFAS fon arama
  final _searchCtrl  = TextEditingController();
  Timer? _debounce;
  List<TefasFund> _fundResults = [];
  bool _searchLoading = false;
  TefasFund? _selectedFund;

  // Hisse arama
  final _stockSearchCtrl = TextEditingController();
  List<({String code, String name, double price, bool isUs})> _stockResults = [];
  bool _stockSearchLoading = false;
  String? _selectedStockCode;

  String _selectedType = 'hisse';
  bool   _isLoading    = false;

  bool get _isFon    => _selectedType == 'fon';
  bool get _isHisse  => _selectedType == 'hisse';

  late final TefasDataSource _tefas;

  static const _types = <String, String>{
    'hisse':   'Hisse',
    'fon':     'TEFAS Fonu',
    'altin':   'Altın',
    'crypto':  'Kripto',
    'doviz':   'Döviz',
    'mevduat': 'Mevduat',
  };

  static const _typeIcons = <String, IconData>{
    'hisse':   Icons.show_chart,
    'fon':     Icons.pie_chart_outline,
    'altin':   Icons.monetization_on_outlined,
    'crypto':  Icons.currency_bitcoin,
    'doviz':   Icons.attach_money,
    'mevduat': Icons.account_balance_outlined,
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'hisse';
    _tefas = GetIt.instance<TefasDataSource>();
    _searchCtrl.addListener(_onFonSearchChanged);
    _stockSearchCtrl.addListener(_onStockSearchChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _searchCtrl.dispose();
    _stockSearchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── TEFAS Fon Arama ────────────────────────────────────────────────────────

  void _onFonSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      setState(() { _fundResults = []; _searchLoading = false; });
      return;
    }
    setState(() => _searchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _tefas.searchFunds(q);
      if (mounted) setState(() { _fundResults = results; _searchLoading = false; });
    });
  }

  Future<void> _selectFund(TefasFund fund) async {
    setState(() {
      _selectedFund  = fund;
      _fundResults   = [];
      _searchLoading = false;
    });
    _searchCtrl.text = '${fund.code} — ${fund.name}';
    _nameCtrl.text   = '${fund.code} - ${fund.name}';
  }

  // ── Hisse Arama (Firestore'dan) ────────────────────────────────────────────

  void _onStockSearchChanged() {
    _debounce?.cancel();
    final q = _stockSearchCtrl.text.trim().toUpperCase();
    if (q.isEmpty) {
      setState(() { _stockResults = []; _stockSearchLoading = false; });
      return;
    }
    setState(() => _stockSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _searchStocks(q);
    });
  }

  Future<void> _searchStocks(String query) async {
    try {
      final db   = FirebaseFirestore.instance;
      final snap = await db.doc('market/live_prices').get();
      if (!snap.exists) { if (mounted) setState(() => _stockSearchLoading = false); return; }

      final data = snap.data();
      final results = <({String code, String name, double price, bool isUs})>[];

      // BIST hisseleri
      final stocks = data?['stocks'] as Map<String, dynamic>?;
      if (stocks != null) {
        for (final entry in stocks.entries) {
          final code = entry.key;
          final val  = entry.value as Map<String, dynamic>?;
          if (val == null) continue;
          final name = (val['name'] as String?) ?? code;
          if (code.toUpperCase().contains(query) || name.toUpperCase().contains(query)) {
            results.add((
              code: code,
              name: name,
              price: _toDouble(val['price']),
              isUs: false,
            ));
          }
        }
      }

      results.sort((a, b) => a.code.compareTo(b.code));
      if (mounted) setState(() {
        _stockResults      = results;
        _stockSearchLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _stockSearchLoading = false);
    }
  }

  Future<void> _selectStock(String code, String name, double price, bool isUs) async {
    setState(() {
      _selectedStockCode = code;
      _stockResults      = [];
      _stockSearchLoading = false;
    });
    _stockSearchCtrl.text = '$code — $name';
    _nameCtrl.text = '$code - $name';
    if (price > 0) {
      _priceCtrl.text = price.toStringAsFixed(4);
    }
  }

  // ── Form Gönder ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final vm  = context.read<PortfolioViewModel>();
    final err = await vm.addAsset(
      type:     _selectedType,
      name:     _nameCtrl.text.trim(),
      quantity: double.parse(_qtyCtrl.text.replaceAll(',', '.')),
      buyPrice: double.parse(_priceCtrl.text.replaceAll(',', '.')),
      currentPrice: _isFon && _selectedFund != null && _selectedFund!.currentPrice > 0
          ? _selectedFund!.currentPrice
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err), backgroundColor: AppColors.accentRed,
      ));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Varlık portföye eklendi ✓'),
        backgroundColor: AppColors.accentGreen,
      ));
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Varlık Ekle', style: AppTypography.headlineS),
              const SizedBox(height: 20),

              // ── Varlık Tipi ─────────────────────────────────────────────────
              _label('Tip'),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _types.entries.map((e) {
                    final sel = _selectedType == e.key;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedType       = e.key;
                        _selectedFund       = null;
                        _selectedStockCode  = null;
                        _fundResults        = [];
                        _stockResults       = [];
                        _searchCtrl.clear();
                        _stockSearchCtrl.clear();
                        _nameCtrl.clear();
                        _priceCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.accentGreen.withOpacity(0.15) : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: sel ? AppColors.accentGreen : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcons[e.key], size: 14,
                              color: sel ? AppColors.accentGreen : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(e.value, style: AppTypography.labelS.copyWith(
                              color: sel ? AppColors.accentGreen : AppColors.textSecondary,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── FON: TEFAS Arama ─────────────────────────────────────────────
              if (_isFon) ...[
                _label('Fon Ara (kod veya isim)'),
                const SizedBox(height: 6),
                _buildSearchField(
                  controller: _searchCtrl,
                  hint: 'TEC, AAK, Teknoloji...',
                ),
                const SizedBox(height: 4),
                if (_searchLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen))),
                  ),
                if (_fundResults.isNotEmpty)
                  _buildFundResults(),
                if (_selectedFund != null && _fundResults.isEmpty)
                  _buildSelectedFundChip(),
                const SizedBox(height: 14),
              ],

              // ── HİSSE: BIST ─────────────────────────────────────────────────
              if (_isHisse) ...[
                // Arama kutusu
                _buildSearchField(
                  controller: _stockSearchCtrl,
                  hint: 'GARAN, BIMAS, THYAO...',
                ),
                const SizedBox(height: 8),

                // Arama sonuçları
                if (_stockSearchLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen))),
                  ),
                if (_stockResults.isNotEmpty)
                  _buildStockResults(),

                // Popüler hisseler (arama yoksa)
                if (_stockSearchCtrl.text.isEmpty && _selectedStockCode == null) ...[
                  Text('Popüler', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  _buildPopularStocks(),
                ],

                if (_selectedStockCode != null && _stockResults.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.accentGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(_selectedStockCode!, style: AppTypography.labelS.copyWith(
                          color: AppColors.accentGreen, fontWeight: FontWeight.w700,
                        )),
                        const SizedBox(width: 4),
                        Text('seçildi', style: AppTypography.labelS.copyWith(
                          color: AppColors.accentGreen,
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],

              // ── Diğer tipler: Manuel isim ────────────────────────────────────
              if (!_isFon && !_isHisse) ...[
                _label('Varlık Adı / Kodu'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: _getHint(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
                ),
                const SizedBox(height: 14),
              ],

              // ── Hisse: sadece isim alanı yoksa, miktar + fiyat göster ────────
              if (_isHisse && _nameCtrl.text.isEmpty)
                const SizedBox.shrink(),

              // ── Miktar + Fiyat ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(_isFon ? 'Pay Sayısı' : _isHisse ? 'Lot / Adet' : 'Adet'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _qtyCtrl,
                          hint: _isFon ? '1000' : '1',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Gerekli';
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n == null || n <= 0) return 'Geçersiz';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(_isFon ? 'Alış NAV (TL)' : 'Alış Fiyatı (TL)'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _priceCtrl,
                          hint: _isFon ? '1.2345' : '42.50',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Gerekli';
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n == null || n <= 0) return 'Geçersiz';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Önizleme ────────────────────────────────────────────────────
              if (_isFon && _selectedFund != null && _selectedFund!.currentPrice > 0)
                _FundPnlPreview(
                  fund: _selectedFund!, qtyCtrl: _qtyCtrl, priceCtrl: _priceCtrl,
                ),
              if (!_isFon)
                _TotalPreview(qtyCtrl: _qtyCtrl, priceCtrl: _priceCtrl,
                    currencySymbol: 'TL'),

              const SizedBox(height: 24),

              // ── Kaydet ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text('Portföye Ekle', style: AppTypography.labelM.copyWith(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget Builders ────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: AppTypography.labelS.copyWith(color: AppColors.textSecondary));

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) =>
      TextFormField(
        controller: controller,
        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      _selectedFund = null; _fundResults = [];
                      _selectedStockCode = null; _stockResults = [];
                      _nameCtrl.clear(); _priceCtrl.clear();
                    });
                  })
              : null,
          filled: true,
          fillColor: AppColors.bgTertiary,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller:      controller,
        keyboardType:    keyboardType,
        inputFormatters: inputFormatters,
        validator:       validator,
        onChanged:       (_) => setState(() {}),
        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 14),
          filled:    true,
          fillColor: AppColors.bgTertiary,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentRed, width: 1)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _buildFundResults() => Container(
    constraints: const BoxConstraints(maxHeight: 220),
    decoration: BoxDecoration(
      color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _fundResults.length,
      itemBuilder: (_, i) {
        final f = _fundResults[i];
        return InkWell(
          onTap: () => _selectFund(f),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(f.code, style: GoogleFonts.dmMono(
                    color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w700,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: AppTypography.labelS.copyWith(color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(f.type, style: AppTypography.labelS.copyWith(
                        color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(f.currentPrice > 0 ? '${f.currentPrice.toStringAsFixed(4)} TL' : '—',
                        style: GoogleFonts.dmMono(color: AppColors.textPrimary, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    if (f.monthlyReturn != 0)
                      Text('${f.monthlyReturn >= 0 ? "+" : ""}${f.monthlyReturn.toStringAsFixed(1)}% /ay',
                          style: AppTypography.labelS.copyWith(
                            color: f.monthlyReturn >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _buildSelectedFundChip() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.accentGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${_selectedFund!.code} — ${_selectedFund!.name}',
              style: AppTypography.labelS.copyWith(color: AppColors.accentGreen)),
        ),
        if (_selectedFund!.yearlyReturn != 0)
          Text('${_selectedFund!.yearlyReturn >= 0 ? "+" : ""}${_selectedFund!.yearlyReturn.toStringAsFixed(1)}% /yıl',
              style: AppTypography.labelS.copyWith(
                color: _selectedFund!.yearlyReturn >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                fontWeight: FontWeight.w700,
              )),
      ],
    ),
  );

  Widget _buildStockResults() => Container(
    constraints: const BoxConstraints(maxHeight: 200),
    decoration: BoxDecoration(
      color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _stockResults.length,
      itemBuilder: (_, i) {
        final s = _stockResults[i];
        return InkWell(
          onTap: () => _selectStock(s.code, s.name, s.price, false),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(s.code, style: GoogleFonts.dmMono(
                    color: AppColors.accentBlue,
                    fontSize: 11, fontWeight: FontWeight.w700,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s.name, style: AppTypography.labelS.copyWith(
                  color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(
                  s.price > 0 ? '${s.price.toStringAsFixed(2)} TL' : '—',
                  style: GoogleFonts.dmMono(color: AppColors.textPrimary, fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _buildPopularStocks() {
    const list = _popularBist;
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          return GestureDetector(
            onTap: () async {
              setState(() => _stockSearchLoading = true);
              await _fetchAndSelectStock(s.$1, s.$2, false);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedStockCode == s.$1
                    ? AppColors.accentGreen.withOpacity(0.15)
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _selectedStockCode == s.$1
                      ? AppColors.accentGreen
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(s.$1, style: AppTypography.labelS.copyWith(
                color: _selectedStockCode == s.$1
                    ? AppColors.accentGreen
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchAndSelectStock(String code, String name, bool isUs) async {
    try {
      final db   = FirebaseFirestore.instance;
      final snap = await db.doc('market/live_prices').get();
      double price = 0;
      if (snap.exists) {
        final data    = snap.data();
        final section = data?['stocks'] as Map<String, dynamic>?;
        final entry   = section?[code] as Map<String, dynamic>?;
        price = _toDouble(entry?['price']);
      }
      await _selectStock(code, name, price, false);
    } catch (_) {
      await _selectStock(code, name, 0, false);
    } finally {
      if (mounted) setState(() => _stockSearchLoading = false);
    }
  }

  String _getHint() {
    switch (_selectedType) {
      case 'altin':   return 'Gram Altın, Çeyrek...';
      case 'crypto':  return 'BTC, ETH, SOL...';
      case 'doviz':   return 'USD, EUR, GBP...';
      case 'mevduat': return 'Garanti Vadeli Hesap';
      default:        return 'Varlık adı';
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ── Fon Kâr/Zarar Önizlemesi ──────────────────────────────────────────────────
class _FundPnlPreview extends StatefulWidget {
  final TefasFund fund;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  const _FundPnlPreview({
    required this.fund,
    required this.qtyCtrl,
    required this.priceCtrl,
  });

  @override
  State<_FundPnlPreview> createState() => _FundPnlPreviewState();
}

class _FundPnlPreviewState extends State<_FundPnlPreview> {
  @override
  void initState() {
    super.initState();
    widget.qtyCtrl.addListener(_rebuild);
    widget.priceCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.qtyCtrl.removeListener(_rebuild);
    widget.priceCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty    = double.tryParse(widget.qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final buyNAV = double.tryParse(widget.priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final currNAV = widget.fund.currentPrice;

    if (qty <= 0 || buyNAV <= 0) return const SizedBox.shrink();

    final cost     = qty * buyNAV;
    final value    = qty * currNAV;
    final pnl      = value - cost;
    final pnlPct   = buyNAV > 0 ? (pnl / cost) * 100 : 0.0;
    final isProfit = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isProfit ? AppColors.accentGreen : AppColors.accentRed).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isProfit ? AppColors.accentGreen : AppColors.accentRed).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _row('Maliyet', _fmt(cost)),
          const SizedBox(height: 6),
          _row('Güncel Değer (NAV)', _fmt(value)),
          const Divider(color: AppColors.borderSubtle, height: 16),
          _row(
            'Kâr / Zarar',
            '${isProfit ? "+" : ""}${_fmt(pnl)} (${pnlPct >= 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
            bold: true,
            color: isProfit ? AppColors.accentGreen : AppColors.accentRed,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTypography.labelS.copyWith(
        color: bold ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      )),
      Text(value, style: AppTypography.labelM.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color,
      )),
    ],
  );

  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${v < 0 ? "-" : ""}$intPart,${parts[1]} TL';
  }
}

// ── Toplam Maliyet Önizleme ────────────────────────────────────────────────────
class _TotalPreview extends StatefulWidget {
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final String currencySymbol;

  const _TotalPreview({
    required this.qtyCtrl,
    required this.priceCtrl,
    this.currencySymbol = 'TL',
  });

  @override
  State<_TotalPreview> createState() => _TotalPreviewState();
}

class _TotalPreviewState extends State<_TotalPreview> {
  @override
  void initState() {
    super.initState();
    widget.qtyCtrl.addListener(_rebuild);
    widget.priceCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.qtyCtrl.removeListener(_rebuild);
    widget.priceCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty   = double.tryParse(widget.qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(widget.priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final total = qty * price;
    if (total <= 0) return const SizedBox.shrink();

    final isUsd = widget.currencySymbol == '\$';
    String formatted;
    if (isUsd) {
      formatted = '\$${total.toStringAsFixed(2)}';
    } else {
      final s = total.toStringAsFixed(2);
      final parts = s.split('.');
      final intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      formatted = '$intPart,${parts[1]} TL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Toplam maliyet',
              style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
          Text(formatted, style: AppTypography.labelM.copyWith(
              color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
