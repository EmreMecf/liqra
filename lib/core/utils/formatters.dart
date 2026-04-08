/// Para ve tarih formatlama yardımcıları
/// Türk formatı: Binlik ayraç = nokta, ondalık = virgül
class Formatters {
  /// TL para birimi: 289.847 TL
  static String currency(double amount, {bool showSymbol = true}) {
    final int rounded = amount.round();
    final String raw = rounded.abs().toString();
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = raw.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(raw[i]);
      count++;
    }
    final String formatted =
        (rounded < 0 ? '-' : '') + buf.toString().split('').reversed.join();
    return showSymbol ? '$formatted TL' : formatted;
  }

  /// Ondalıklı TL: 289.847,50 TL
  static String currencyDecimal(double amount, {bool showSymbol = true}) {
    final String intPart = currency(amount.truncateToDouble(),
        showSymbol: false);
    final int dec = ((amount.abs() - amount.abs().truncate()) * 100).round();
    final String decStr = dec.toString().padLeft(2, '0');
    return showSymbol ? '$intPart,$decStr TL' : '$intPart,$decStr';
  }

  /// Yüzde: +12,4% veya -3,2%
  static String percent(double value, {bool showSign = true}) {
    final String sign = (showSign && value > 0) ? '+' : '';
    final String formatted = value.abs() < 10
        ? value.toStringAsFixed(1).replaceAll('.', ',')
        : value.toStringAsFixed(0);
    return '$sign${value < 0 ? "-" : ""}$formatted%';
  }

  /// Kısa sayı: 289.847 → 289,8B veya 1.240.000 → 1,2M
  static String compact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1).replaceAll('.', ',')}B';
    }
    return currency(amount);
  }

  /// Tarih: 23 Mar 2026
  static String date(DateTime d) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  /// Kısa tarih: 23 Mar
  static String shortDate(DateTime d) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${d.day} ${months[d.month]}';
  }

  /// Ay-Yıl: Mart 2026
  static String monthYear(DateTime d) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[d.month]} ${d.year}';
  }

  /// Frekans etiketi
  static String frequency(String freq) {
    switch (freq) {
      case 'monthly':
        return 'Aylık';
      case 'annual':
        return 'Yıllık';
      case 'weekly':
        return 'Haftalık';
      default:
        return freq;
    }
  }
}
