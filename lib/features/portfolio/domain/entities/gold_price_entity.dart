/// Altın fiyatı veri modeli (alış + satış + değişim)
class GoldPriceData {
  final String code;       // "gram", "ceyrek", "tam", "bilezik22" …
  final String name;       // "Gram Altın", "Çeyrek Altın" …
  final String icon;       // emoji
  final String unit;       // "Gram", "Adet", "Gram/Gr"
  final double alis;       // TL — birim başı alış fiyatı
  final double satis;      // TL — birim başı satış fiyatı
  final double degisim;    // % günlük değişim
  final double degisimTutar; // TL günlük değişim tutarı
  final String category;  // "madeni" | "bilezik" | "diger"

  const GoldPriceData({
    required this.code,
    required this.name,
    required this.icon,
    required this.unit,
    required this.alis,
    required this.satis,
    required this.degisim,
    this.degisimTutar = 0,
    required this.category,
  });

  double get mid => (alis + satis) / 2;
  double get spread => satis - alis;
  bool   get isUp => degisim >= 0;
}
