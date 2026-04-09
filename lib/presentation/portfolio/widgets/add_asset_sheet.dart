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

// ── Meta tablolar ─────────────────────────────────────────────────────────────

const _popularBist = [
  ('GARAN', 'Garanti BBVA'),      ('BIMAS', 'BİM Mağazalar'),
  ('THYAO', 'Türk Hava Yolları'), ('AKBNK', 'Akbank'),
  ('ASELS', 'Aselsan'),           ('EREGL', 'Ereğli Demir'),
  ('SISE',  'Şişecam'),           ('KCHOL', 'Koç Holding'),
  ('ISCTR', 'İş Bankası C'),      ('SAHOL', 'Sabancı Holding'),
  ('TCELL', 'Turkcell'),          ('FROTO', 'Ford Otomotiv'),
  ('PGSUS', 'Pegasus'),           ('YKBNK', 'Yapı Kredi'),
  ('TUPRS', 'Tüpraş'),
];

/// Altın tipleri: (priceKey, displayName, icon)
const _goldTypes = [
  ('gram',        'Gram Altın',         '🥇'),
  ('ceyrek',      'Çeyrek Altın',       '🪙'),
  ('yarim',       'Yarım Altın',        '🪙'),
  ('tam',         'Tam Altın',          '🥇'),
  ('cumhuriyet',  'Cumhuriyet Altını',  '🏅'),
  ('ons',         'Ons Altın',          '🥇'),
  ('gumus',       'Gümüş',              '🔘'),
];

/// Kripto tipleri: (priceKey, displayName, icon)
const _cryptoTypes = [
  ('BTC_TRY',  'Bitcoin',  '₿'),
  ('ETH_TRY',  'Ethereum', '⟠'),
  ('SOL_TRY',  'Solana',   '◎'),
  ('BNB_TRY',  'BNB',      '🔶'),
  ('XRP_TRY',  'XRP',      '✕'),
  ('DOGE_TRY', 'Dogecoin', '🐕'),
  ('USDT_TRY', 'Tether',   '💲'),
];

/// Döviz tipleri: (priceKey, displayName, flag)
const _dovizTypes = [
  ('USDTRY', 'Dolar (USD)',        '🇺🇸'),
  ('EURTRY', 'Euro (EUR)',         '🇪🇺'),
  ('GBPTRY', 'Sterlin (GBP)',      '🇬🇧'),
  ('CHFTRY', 'İsv. Frangı (CHF)', '🇨🇭'),
];

// ── Widget ────────────────────────────────────────────────────────────────────

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
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<TefasFund> _fundResults   = [];
  bool _searchLoading             = false;
  TefasFund? _selectedFund;

  // Hisse arama
  final _stockSearchCtrl = TextEditingController();
  List<({String code, String name, double price, bool isUs})> _stockResults = [];
  bool _stockSearchLoading = false;
  String? _selectedStockCode;

  // Altın / Kripto / Döviz seçimi
  String? _selectedSubKey;   // priceKey: "gram", "BTC_TRY", "USDTRY" ...
  String? _selectedSubName;  // Görüntü adı
  double  _livePrice = 0;    // Anlık fiyat

  String _selectedType = 'hisse';
  bool   _isLoading    = false;

  bool get _isFon    => _selectedType == 'fon';
  bool get _isHisse  => _selectedType == 'hisse';
  bool get _isAltin  => _selectedType == 'altin';
  bool get _isCrypto => _selectedType == 'crypto';
  bool get _isDoviz  => _selectedType == 'doviz';
  bool get _isMevduat => _selectedType == 'mevduat';

  // priceSection ve priceKey her tip için
  String? get _priceSection {
    if (_isAltin)  return 'gold';
    if (_isCrypto) return 'prices';
    if (_isDoviz)  return 'prices';
    if (_isHisse)  return 'stocks';
    if (_isFon)    return 'funds';
    return null;
  }
  String? get _priceKey {
    if (_isHisse) return _selectedStockCode;
    if (_isFon)   return _selectedFund?.code;
    return _selectedSubKey;
  }

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
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose();
    _searchCtrl.dispose(); _stockSearchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── TEFAS Fon Arama ─────────────────────────────────────────────────────────

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
    setState(() { _selectedFund = fund; _fundResults = []; _searchLoading = false; });
    _searchCtrl.text = '${fund.code} — ${fund.name}';
    _nameCtrl.text   = '${fund.code} - ${fund.name}';
    if (fund.currentPrice > 0) _priceCtrl.text = fund.currentPrice.toStringAsFixed(4);
  }

  // ── Hisse Arama ─────────────────────────────────────────────────────────────

  void _onStockSearchChanged() {
    _debounce?.cancel();
    final q = _stockSearchCtrl.text.trim().toUpperCase();
    if (q.isEmpty) { setState(() { _stockResults = []; _stockSearchLoading = false; }); return; }
    setState(() => _stockSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async => _searchStocks(q));
  }

  Future<void> _searchStocks(String query) async {
    try {
      final snap = await FirebaseFirestore.instance.doc('market/live_prices').get();
      if (!snap.exists) { if (mounted) setState(() => _stockSearchLoading = false); return; }
      final data    = snap.data();
      final results = <({String code, String name, double price, bool isUs})>[];
      final stocks  = data?['stocks'] as Map<String, dynamic>?;
      if (stocks != null) {
        for (final e in stocks.entries) {
          final code = e.key;
          final val  = e.value as Map<String, dynamic>?;
          if (val == null) continue;
          final name = (val['name'] as String?) ?? code;
          if (code.contains(query) || name.toUpperCase().contains(query)) {
            results.add((code: code, name: name, price: _toDouble(val['price']), isUs: false));
          }
        }
      }
      results.sort((a, b) => a.code.compareTo(b.code));
      if (mounted) setState(() { _stockResults = results; _stockSearchLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _stockSearchLoading = false);
    }
  }

  Future<void> _selectStock(String code, String name, double price) async {
    setState(() { _selectedStockCode = code; _stockResults = []; _stockSearchLoading = false; });
    _stockSearchCtrl.text = '$code — $name';
    _nameCtrl.text = '$code - $name';
    if (price > 0) _priceCtrl.text = price.toStringAsFixed(2);
  }

  Future<void> _fetchAndSelectStock(String code, String name) async {
    try {
      final snap = await FirebaseFirestore.instance.doc('market/live_prices').get();
      double price = 0;
      if (snap.exists) {
        final entry = (snap.data()?['stocks'] as Map?)?[code] as Map?;
        price = _toDouble(entry?['price']);
      }
      await _selectStock(code, name, price);
    } catch (_) {
      await _selectStock(code, name, 0);
    } finally {
      if (mounted) setState(() => _stockSearchLoading = false);
    }
  }

  // ── Altın / Kripto / Döviz Seçimi ───────────────────────────────────────────

  Future<void> _selectSubType(String priceKey, String displayName, String section) async {
    setState(() { _selectedSubKey = priceKey; _selectedSubName = displayName; _livePrice = 0; });
    _nameCtrl.text = displayName;

    // Canlı fiyatı Firestore'dan çek
    try {
      final snap = await FirebaseFirestore.instance.doc('market/live_prices').get();
      if (!snap.exists) return;
      final data = snap.data()!;
      double price = 0;

      if (section == 'gold') {
        final entry = (data['gold'] as Map?)?[priceKey] as Map<String, dynamic>?;
        final alis  = _toDouble(entry?['alis']);
        final satis = _toDouble(entry?['satis']);
        price = alis > 0 ? alis : satis;
      } else {
        // prices (kripto + döviz)
        price = _toDouble((data['prices'] as Map?)?[priceKey]?['price']);
      }

      if (mounted && price > 0) {
        setState(() => _livePrice = price);
        _priceCtrl.text = price.toStringAsFixed(price >= 1000 ? 2 : 4);
      }
    } catch (_) {}
  }

  // ── Form Gönder ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Tip bazlı ek validasyon
    if ((_isAltin || _isCrypto || _isDoviz) && _selectedSubKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen bir tür seçin'),
        backgroundColor: AppColors.accentRed,
      ));
      return;
    }
    if (_isHisse && _selectedStockCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen bir hisse seçin'),
        backgroundColor: AppColors.accentRed,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final vm  = context.read<PortfolioViewModel>();
    final err = await vm.addAsset(
      type:         _selectedType,
      name:         _nameCtrl.text.trim(),
      quantity:     double.parse(_qtyCtrl.text.replaceAll(',', '.')),
      buyPrice:     double.parse(_priceCtrl.text.replaceAll(',', '.')),
      currentPrice: _isFon && _selectedFund != null && _selectedFund!.currentPrice > 0
          ? _selectedFund!.currentPrice
          : _livePrice > 0 ? _livePrice : null,
      priceSection: _priceSection,
      priceKey:     _priceKey,
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

  // ── Build ────────────────────────────────────────────────────────────────────

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
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2),
                ),
              )),

              Text('Varlık Ekle', style: AppTypography.headlineS),
              const SizedBox(height: 20),

              // ── Tip seçici ──────────────────────────────────────────────────
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
                        _selectedType      = e.key;
                        _selectedFund      = null; _selectedStockCode = null;
                        _selectedSubKey    = null; _selectedSubName   = null;
                        _livePrice         = 0;
                        _fundResults       = []; _stockResults      = [];
                        _searchCtrl.clear(); _stockSearchCtrl.clear();
                        _nameCtrl.clear(); _priceCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.accentGreen.withOpacity(0.15) : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: sel ? AppColors.accentGreen : AppColors.borderSubtle),
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

              // ── ALTIN Seçici ────────────────────────────────────────────────
              if (_isAltin) ...[
                _label('Altın Türü'),
                const SizedBox(height: 8),
                _buildSubTypeGrid(_goldTypes, 'gold'),
                if (_selectedSubKey != null && _livePrice > 0) ...[
                  const SizedBox(height: 8),
                  _LivePriceChip(price: _livePrice, label: _selectedSubName ?? '', section: 'gold'),
                ],
                const SizedBox(height: 14),
              ],

              // ── KRİPTO Seçici ───────────────────────────────────────────────
              if (_isCrypto) ...[
                _label('Kripto Para'),
                const SizedBox(height: 8),
                _buildSubTypeGrid(_cryptoTypes, 'prices'),
                if (_selectedSubKey != null && _livePrice > 0) ...[
                  const SizedBox(height: 8),
                  _LivePriceChip(price: _livePrice, label: _selectedSubName ?? '', section: 'prices'),
                ],
                const SizedBox(height: 14),
              ],

              // ── DÖVİZ Seçici ────────────────────────────────────────────────
              if (_isDoviz) ...[
                _label('Döviz'),
                const SizedBox(height: 8),
                _buildSubTypeGrid(_dovizTypes, 'prices'),
                if (_selectedSubKey != null && _livePrice > 0) ...[
                  const SizedBox(height: 8),
                  _LivePriceChip(price: _livePrice, label: _selectedSubName ?? '', section: 'prices'),
                ],
                const SizedBox(height: 14),
              ],

              // ── FON Arama ───────────────────────────────────────────────────
              if (_isFon) ...[
                _label('Fon Ara (kod veya isim)'),
                const SizedBox(height: 6),
                _buildSearchField(controller: _searchCtrl, hint: 'TEC, AAK, Teknoloji...'),
                const SizedBox(height: 4),
                if (_searchLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen)))),
                if (_fundResults.isNotEmpty) _buildFundResults(),
                if (_selectedFund != null && _fundResults.isEmpty) _buildSelectedFundChip(),
                const SizedBox(height: 14),
              ],

              // ── HİSSE Arama ─────────────────────────────────────────────────
              if (_isHisse) ...[
                _buildSearchField(controller: _stockSearchCtrl, hint: 'GARAN, BIMAS, THYAO...'),
                const SizedBox(height: 8),
                if (_stockSearchLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen)))),
                if (_stockResults.isNotEmpty) _buildStockResults(),
                if (_stockSearchCtrl.text.isEmpty && _selectedStockCode == null) ...[
                  Text('Popüler', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  _buildPopularStocks(),
                ],
                if (_selectedStockCode != null && _stockResults.isEmpty)
                  _buildSelectedChip(_selectedStockCode!),
                const SizedBox(height: 14),
              ],

              // ── Mevduat: Manuel isim ────────────────────────────────────────
              if (_isMevduat) ...[
                _label('Hesap Adı'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nameCtrl, hint: 'Garanti Vadeli Hesap',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
                ),
                const SizedBox(height: 14),
              ],

              // ── Miktar + Alış Fiyatı ────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(_isFon ? 'Pay Sayısı' : _isHisse ? 'Adet / Lot' : _isAltin ? 'Gram / Adet' : 'Adet'),
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
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Alış Fiyatı (TL)'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _priceCtrl,
                        hint: _livePrice > 0 ? _livePrice.toStringAsFixed(2) : '0.00',
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
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // ── Önizleme ────────────────────────────────────────────────────
              if (_isFon && _selectedFund != null && _selectedFund!.currentPrice > 0)
                _FundPnlPreview(fund: _selectedFund!, qtyCtrl: _qtyCtrl, priceCtrl: _priceCtrl),
              if (!_isFon)
                _TotalPreview(qtyCtrl: _qtyCtrl, priceCtrl: _priceCtrl, livePrice: _livePrice),

              const SizedBox(height: 24),

              // ── Kaydet ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity, height: 52,
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

  // ── SubType Grid (Altın / Kripto / Döviz) ────────────────────────────────────

  Widget _buildSubTypeGrid(
    List<(String, String, String)> types,
    String section,
  ) =>
      Wrap(
        spacing: 8, runSpacing: 8,
        children: types.map((t) {
          final key  = t.$1;
          final name = t.$2;
          final icon = t.$3;
          final sel  = _selectedSubKey == key;
          return GestureDetector(
            onTap: () => _selectSubType(key, name, section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.accentGreen.withOpacity(0.15) : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.accentGreen : AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(name, style: AppTypography.labelS.copyWith(
                    color: sel ? AppColors.accentGreen : AppColors.textPrimary,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      );

  // ── Canlı Fiyat Göstergesi ───────────────────────────────────────────────────

  Widget _buildSelectedChip(String code) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.accentGreen.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 16),
      const SizedBox(width: 8),
      Text(code, style: AppTypography.labelS.copyWith(
        color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
      const SizedBox(width: 4),
      Text('seçildi', style: AppTypography.labelS.copyWith(color: AppColors.accentGreen)),
    ]),
  );

  // ── Builders (ortak) ─────────────────────────────────────────────────────────

  Widget _label(String text) =>
      Text(text, style: AppTypography.labelS.copyWith(color: AppColors.textSecondary));

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
          filled: true, fillColor: AppColors.bgTertiary,
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
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 14),
          filled: true, fillColor: AppColors.bgTertiary,
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
    decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle)),
    child: ListView.builder(
      shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _fundResults.length,
      itemBuilder: (_, i) {
        final f = _fundResults[i];
        return InkWell(
          onTap: () => _selectFund(f),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(f.code, style: GoogleFonts.dmMono(
                    color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: AppTypography.labelS.copyWith(color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(f.type, style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary, fontSize: 10)),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(f.currentPrice > 0 ? '${f.currentPrice.toStringAsFixed(4)} TL' : '—',
                    style: GoogleFonts.dmMono(color: AppColors.textPrimary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (f.monthlyReturn != 0)
                  Text('${f.monthlyReturn >= 0 ? "+" : ""}${f.monthlyReturn.toStringAsFixed(1)}% /ay',
                      style: AppTypography.labelS.copyWith(
                          color: f.monthlyReturn >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                          fontSize: 10)),
              ]),
            ]),
          ),
        );
      },
    ),
  );

  Widget _buildSelectedFundChip() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text('${_selectedFund!.code} — ${_selectedFund!.name}',
          style: AppTypography.labelS.copyWith(color: AppColors.accentGreen))),
      if (_selectedFund!.yearlyReturn != 0)
        Text('${_selectedFund!.yearlyReturn >= 0 ? "+" : ""}${_selectedFund!.yearlyReturn.toStringAsFixed(1)}% /yıl',
            style: AppTypography.labelS.copyWith(
              color: _selectedFund!.yearlyReturn >= 0 ? AppColors.accentGreen : AppColors.accentRed,
              fontWeight: FontWeight.w700,
            )),
    ]),
  );

  Widget _buildStockResults() => Container(
    constraints: const BoxConstraints(maxHeight: 200),
    decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle)),
    child: ListView.builder(
      shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _stockResults.length,
      itemBuilder: (_, i) {
        final s = _stockResults[i];
        return InkWell(
          onTap: () => _selectStock(s.code, s.name, s.price),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(s.code, style: GoogleFonts.dmMono(
                    color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(s.name, style: AppTypography.labelS.copyWith(
                  color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(s.price > 0 ? '${s.price.toStringAsFixed(2)} TL' : '—',
                  style: GoogleFonts.dmMono(color: AppColors.textPrimary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      },
    ),
  );

  Widget _buildPopularStocks() => SizedBox(
    height: 36,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _popularBist.length,
      itemBuilder: (_, i) {
        final s   = _popularBist[i];
        final sel = _selectedStockCode == s.$1;
        return GestureDetector(
          onTap: () async {
            setState(() => _stockSearchLoading = true);
            await _fetchAndSelectStock(s.$1, s.$2);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? AppColors.accentGreen.withOpacity(0.15) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: sel ? AppColors.accentGreen : AppColors.borderSubtle),
            ),
            child: Text(s.$1, style: AppTypography.labelS.copyWith(
              color: sel ? AppColors.accentGreen : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
          ),
        );
      },
    ),
  );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ── Canlı Fiyat Chip ──────────────────────────────────────────────────────────

class _LivePriceChip extends StatelessWidget {
  final double price;
  final String label;
  final String section;

  const _LivePriceChip({required this.price, required this.label, required this.section});

  @override
  Widget build(BuildContext context) {
    final fmt = price >= 10000
        ? price.toStringAsFixed(0)
        : price >= 100
            ? price.toStringAsFixed(2)
            : price.toStringAsFixed(4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Canlı: ', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
          Text('$fmt TL', style: AppTypography.labelS.copyWith(
            color: AppColors.accentBlue, fontWeight: FontWeight.w700,
          )),
          const SizedBox(width: 6),
          Text('· Alış fiyatı otomatik dolduruldu',
              style: AppTypography.labelS.copyWith(color: AppColors.textDisabled, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Fon Kâr/Zarar Önizlemesi ──────────────────────────────────────────────────

class _FundPnlPreview extends StatefulWidget {
  final TefasFund fund;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  const _FundPnlPreview({required this.fund, required this.qtyCtrl, required this.priceCtrl});

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
    final qty     = double.tryParse(widget.qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final buyNAV  = double.tryParse(widget.priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final currNAV = widget.fund.currentPrice;
    if (qty <= 0 || buyNAV <= 0) return const SizedBox.shrink();

    final cost = qty * buyNAV;
    final value = qty * currNAV;
    final pnl   = value - cost;
    final pnlPct = buyNAV > 0 ? (pnl / cost) * 100 : 0.0;
    final isProfit = pnl >= 0;
    final c = isProfit ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(children: [
        _row('Maliyet', _fmt(cost)),
        const SizedBox(height: 6),
        _row('Güncel Değer (NAV)', _fmt(value)),
        const Divider(color: AppColors.borderSubtle, height: 16),
        _row('Kâr / Zarar',
          '${isProfit ? "+" : ""}${_fmt(pnl)} (${pnlPct >= 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
          bold: true, color: c),
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTypography.labelS.copyWith(
        color: bold ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: AppTypography.labelM.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
    ]);

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
  final double livePrice;

  const _TotalPreview({
    required this.qtyCtrl,
    required this.priceCtrl,
    this.livePrice = 0,
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

    // Canlı fiyat ile güncel değer de hesapla
    final liveTotal = widget.livePrice > 0 ? qty * widget.livePrice : 0.0;
    final pnl = liveTotal - total;
    final hasPnl = widget.livePrice > 0 && pnl.abs() > 0.01;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Toplam maliyet', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
          Text(_fmt(total), style: AppTypography.labelM.copyWith(
            color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
        ]),
        if (hasPnl) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Güncel değer', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
            Text(_fmt(liveTotal), style: AppTypography.labelM.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Anlık K/Z', style: AppTypography.labelS.copyWith(color: AppColors.textSecondary)),
            Text('${pnl >= 0 ? "+" : ""}${_fmt(pnl)}',
              style: AppTypography.labelM.copyWith(
                color: pnl >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                fontWeight: FontWeight.w700)),
          ]),
        ],
      ]),
    );
  }

  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${v < 0 ? "-" : ""}$intPart,${parts[1]} TL';
  }
}
