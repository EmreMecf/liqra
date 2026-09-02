/// Kategori slug'larını Türkçe karakterden bağımsız karşılaştırır.
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// Cloud Functions Firestore'a **ASCII slug** yazar (`alisveris`, `doviz`),
/// istemcideki `switch` ise Türkçe karakterli hâli (`alışveriş`, `döviz`)
/// bekliyordu. Hiçbiri eşleşmediği için tüm alışveriş kampanyaları
/// `diger` kategorisine düşüyordu — kategori filtresi ve asistanın kampanya
/// eşleştirmesi bu yüzden çalışmıyordu.
String normalizeCategorySlug(String? raw) => (raw ?? '')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
