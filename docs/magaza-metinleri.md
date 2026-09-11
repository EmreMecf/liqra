# Liqra — Mağaza Metinleri (taslak)

Her iki mağazaya yapıştırılacak metinler. Karakter sınırları
`python` ile ölçülerek kontrol edildi; parantez içindeki sayı mevcut uzunluk.

Bu dosya `docs/_config.yml` içinde `exclude` listesindedir.

## Yazım kuralları — değiştirirken koru

- **"Tavsiye" deme, "analiz" de.** Türkiye'de kişiye özel yatırım danışmanlığı
  SPK lisansı gerektirir; Liqra lisanslı değil. Uygulama içinde de aynı dil
  kullanılıyor.
- **Bankaya bağlandığını ima etme.** Liqra bankaya bağlanmaz; veriyi kullanıcı
  girer ya da belgeden taratır. "Hesaplarını otomatik senkronize et" gibi bir
  cümle mağaza meta verisinde yanlış beyan olur (App Store 2.3.1) ve
  Play'de "banka verisi" beyanı ek doğrulama başlatır.
- **Kampanyaları özellik olarak sunma.** Uygulamadaki banka kampanyalarının
  tamamı örnek içerik; canlı kaynak bağlı değil.
- **Gerçek zamanlı deme.** Piyasa verisi üçüncü taraftan gelir ve gecikmeli
  olabilir.

---

## Uygulama adı

| Mağaza | Metin | Sınır |
|---|---|---|
| App Store (ad) | `Liqra` | 30 |
| Google Play (başlık) | `Liqra: Bütçe ve Portföy` (23) | 30 |

## App Store — alt başlık (30)

```
Harcama, bütçe ve portföy
```
(25)

## Google Play — kısa açıklama (80)

```
Harcamanı, kartlarını ve yatırımlarını tek yerde takip et, Liqra ile analiz et.
```
(79)

## App Store — tanıtım metni (170)

İnceleme gerektirmeden istediğin zaman değiştirebilirsin.

```
Kredi kartı ekstrelerin, bütçe limitlerin ve yatırımların tek ekranda. Liqra harcamanı denetler, birikim planı çıkarır, portföyünü yorumlar.
```
(140)

## App Store — anahtar kelimeler (100)

Virgülle, boşluksuz. Uygulama adı ve alt başlıktaki kelimeler tekrar edilmez
(Apple zaten sayar). Türkçe harfler UTF-8'de 2 bayt tutar; alan bayt
sayıyorsa da sığsın diye 100 **baytı** aşmayacak şekilde tutuldu.

```
harcama takibi,gider,kredi kartı,ekstre,birikim,yatırım,hisse,borsa,altın,döviz,kripto,abonelik
```
(95 karakter, 100 bayt)

---

## Uzun açıklama (her iki mağaza — 4000)

```
Liqra, paranın nereye gittiğini gösteren ve seninle birlikte düşünen kişisel finans asistanıdır. Harcamaların, kredi kartların, kredilerin, bütçen ve yatırımların tek bir uygulamada.

HARCAMA VE BÜTÇE
• Gelir ve giderlerini kategorilere göre takip et
• Fişini ya da faturanı fotoğrafla, Liqra tutarı ve kategoriyi okuyup kaydetsin
• Kategori bazında aylık bütçe limiti koy; limite yaklaşınca ve aşınca haberin olsun
• Aboneliklerini tek listede gör, yenilenme tarihlerini kaçırma

KREDİ KARTLARI VE KREDİLER
• Hesap kesim ve son ödeme tarihlerini Liqra hesaplar; ay sonu, şubat ve artık yıl dahil
• Ekstren kesim gününde otomatik oluşur, asgari ödeme tutarı hazır gelir
• Taksitli alışverişleri aylara böl, hangi ay ne kadar ödeyeceğini gör
• Toplam borç, kullanım oranı ve net servetini tek bakışta izle
• Son ödeme günü yaklaşınca ya da geçince hatırlatma al

YATIRIM PORTFÖYÜ
• BIST hisseleri, altın, döviz, kripto paralar ve yatırım fonları
• Kâr/zarar, portföy dağılımı ve varlık ağırlıkları
• Hedef belirle; birikimin portföyünle birlikte hedefe doğru ilerlesin

LİQRA ASİSTAN
Liqra yapay zekâ destekli bir finans asistanıdır ve senin gerçek rakamlarınla konuşur.
• Harcama denetimi: hangi kategoride ne kadar arttığını ve nedenini gösterir
• Birikim planı: hedefine ulaşmak için hangi harcamadan ne kadar kısabileceğini hesaplar
• Hisse analizi: fiyat hareketi, ilgili haberler, sektör ve makro duyarlılık, senin pozisyonun ve riskler
• Proaktif bulgular: gecikmiş ödeme, bütçe aşımı, atıl nakit gibi durumları kendiliğinden fark eder

Rakamları uygulama hesaplar, Liqra yorumlar — tutarlar uydurulmaz.

FİNANS HABERLERİ
Güncel ekonomi ve piyasa haberleri; asistan hisse analizinde ilgili haberleri de dikkate alır.

GİZLİLİK
• Liqra bankalarına bağlanmaz; verileri sen girersin ya da belgelerinden taratırsın
• Banka şifresi veya kart numarasının tamamı istenmez
• Verilerin yalnızca senin hesabında durur, satılmaz, reklam için kullanılmaz
• Hesabını ve tüm verilerini uygulama içinden kalıcı olarak silebilirsin

ÖNEMLİ
Liqra'nın analizleri bilgilendirme amaçlıdır, yatırım tavsiyesi değildir. Yatırım kararlarının sorumluluğu kullanıcıya aittir. Piyasa verileri üçüncü taraf kaynaklardan gelir ve gecikmeli olabilir.

Gizlilik politikası: https://emremecf.github.io/liqra/gizlilik-politikasi
```

---

## Sürüm notu (ilk sürüm)

```
Liqra'nın ilk sürümü: harcama ve bütçe takibi, kredi kartı ekstre döngüsü, yatırım portföyü ve Liqra asistan.
```

---

## Apple — App Review notu (İngilizce)

App Store Connect → sürüm sayfası → **App Review Information → Notes**.
İnceleme ekibi İngilizce çalışır; uygulamanın Türkçe olduğunu ve neyi
yapmadığını baştan söylemek "ne yapıyor anlamadık" retlerini önler.

```
Liqra is a personal finance tracker for users in Turkey. The app UI is in Turkish.

DEMO ACCOUNT
The demo account above is pre-filled with sample data: a bank account, a credit card with a statement, transactions, a budget limit, portfolio assets and a savings goal.

WHAT THE APP DOES NOT DO
- It does not connect to any bank. All financial data is entered manually by the user or read from receipts/statements the user scans.
- It does not execute trades, transfers or payments, and does not offer loans.

AI ASSISTANT
The "Liqra" tab uses Google Gemini to explain the user's own spending, build a savings plan and analyze a stock. All numbers are calculated by the app; the model only explains them. Every investment analysis shows an on-screen disclaimer that it is informational and not investment advice, and the model is instructed not to give buy/sell recommendations.

OTHER NOTES
- Market prices come from third-party data providers and may be delayed.
- Bank campaigns on the "Keşfet" (Discover) screen, opened from the + button menu, are sample content and are labeled "Örnek" (Sample).
- Account deletion: Profil (Profile) > Hesabı Sil (Delete Account). It deletes the account and all data.
- Sign in with Apple is available on the login screen.
- The camera is used only to scan receipts; no location data is collected.
```

---

## Google Play — Uygulama erişimi talimatı

Play Console → Uygulama içeriği → **Uygulama erişimi** → "Tüm işlevler
kısıtlı değil" değil, **"İşlevlerin tamamı veya bir kısmı kısıtlı"** →
talimat ekle:

```
Uygulama giriş gerektirir. Aşağıdaki inceleme hesabı örnek verilerle doldurulmuştur: banka hesabı, ekstresi kesilmiş kredi kartı, işlemler, bütçe limiti, portföy ve birikim hedefi.

Giriş ekranında e-posta ve şifreyi girip "Giriş Yap" düğmesine dokunun.
```

Kullanıcı adı ve şifre alanlarına 0.4'teki inceleme hesabını gir.

---

## Ekran görüntüsü önerisi (sıra önemli)

İlk iki görüntü mağaza aramasında görünür; en güçlü iki özellik başa.

1. **Ana sayfa** — net servet, bu ayın harcaması, asistan bulguları
2. **Kredi kartı** — ekstre, son ödeme günü, kullanım oranı
3. **Liqra asistan** — harcama denetimi yanıtı (alt kısmındaki uyarı görünsün)
4. **Bütçe limitleri** — ilerleme çubukları, aşılan kategori
5. **Portföy** — dağılım grafiği, kâr/zarar
6. **Hisse analizi** — başlıklar ve alttaki uyarı
7. **Fiş tarama**

Ekran görüntülerini **inceleme hesabındaki örnek veriyle** al — kendi gerçek
bakiyeni mağazaya koyma.

Boyutlar: App Store 1320×2868 (6.9") · Play en az 1080 px kısa kenar, 9:16.
