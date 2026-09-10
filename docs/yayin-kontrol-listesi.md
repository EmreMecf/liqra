# Liqra — Yayın Kontrol Listesi

Son denetim: 10 Eylül 2026 · `flutter analyze` temiz · 164 test geçiyor

Bu dosya `docs/_config.yml` içinde `exclude` listesindedir — GitHub Pages'te
yayınlanmaz, depoda kalır.

---

## ✅ Tamamlananlar

Bu maddeler daha önce "yayına engel" listesindeydi; artık kapalı.

| Konu | Durum |
|---|---|
| iOS Firebase yapılandırması | `firebase_options.dart` iOS bloğu eklendi · `firebase.json` iOS platformunu tanıyor |
| iOS izin metinleri | Kamera, galeri, galeriye kaydetme, Face ID, konum (uyarı 90683) |
| iOS dağıtım hedefi | `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (3 yapılandırma) + `AppFrameworkInfo.plist` — uyarı 90068 kapandı |
| iOS yetkiler | `Runner.entitlements` · `aps-environment: production` · Apple ile Giriş |
| Cihaz ailesi | `TARGETED_DEVICE_FAMILY = 1` — yalnızca iPhone |
| Google girişi URL şeması | Codemagic her derlemede plist'ten okuyup yazıyor |
| Android yedekleme | `allowBackup=false` + `backup_rules.xml` + `data_extraction_rules.xml` |
| Android imzalama yapılandırması | `key.properties` okunuyor; Codemagic dosyayı üretiyor |
| Android küçültme | `isMinifyEnabled` + `isShrinkResources` + ProGuard kuralları |
| Hesap silme | Profil → Hesabı Sil gerçekten siliyor (App Store 5.1.1(v)) |
| Açılış dayanıklılığı | Yardımcı servis patlarsa uygulama yine açılıyor; siyah ekran yerine sebep gösteriliyor |
| Gizlilik politikası URL'si | **Yayında** → https://emremecf.github.io/liqra/gizlilik-politikasi |
| CI hattı | Codemagic 3 iş akışı: android-release, ios-release, quality-check |

### Gizlilik politikası adresi

Her iki mağaza formuna da bu adres girilecek:

```
https://emremecf.github.io/liqra/gizlilik-politikasi
```

Doğrulandı: HTTP 200, `lang="tr-TR"`, içerik doğru.

---

## 🔴 Kalan engeller

### 1. Android imzalama anahtarı — Codemagic'te var mı?

iOS tarafı TestFlight'a kadar gitti, **Android sürüm derlemesi henüz hiç
çalışmadı**. Codemagic'te şunun bulunduğunu doğrula:

> Codemagic → Teams / App settings → **Code signing identities** →
> **Android keystores** → referans adı `liqra_keystore`

Yoksa önce anahtarı üret ve yükle:

```powershell
keytool -genkey -v -keystore liqra-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias liqra
```

⚠️ **Bu dosyayı kaybetme.** Kaybedersen aynı uygulamayı bir daha
güncelleyemezsin — Play yeni paket adı ister. Yedeğini şifreli bir yerde tut.

`codemagic.yaml` artık anahtar üretilmediyse derlemeyi **başlamadan
durduruyor**. Eskiden `build.gradle.kts` sessizce debug anahtarına düşüyor,
`.aab` Play'e yükleniyor ve dakikalar sonra reddediliyordu.

### 2. Play Store servis hesabı

`android-release` iş akışı `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` bekliyor
(`google_play` değişken grubu). Play Console → Setup → API access →
service account JSON.

### 3. TestFlight test grubu — yapı kimseye ulaşmıyor

Yapı App Store Connect'e yükleniyor ve "Ready to Test" oluyor ama **hiçbir
test grubuna atanmıyordu**; TestFlight uygulamasında hiçbir şey görünmüyor,
ortada hata da olmuyor.

`codemagic.yaml` artık `beta_groups: [Liqra Test]` gönderiyor. Bu adla bir
grup **önce oluşturulmalı**, yoksa derleme yayın adımında durur:

> App Store Connect → TestFlight → **Gruplar** → + → ad: `Liqra Test`

Grup türü:

| Tür | İnceleme | Kimler |
|---|---|---|
| **Internal Testing** | yok, dakikalar içinde | App Store Connect'te kullanıcı olarak tanımlı kişiler (en fazla 100) |
| External Testing | Beta App Review gerekir | E-posta ile davet edilen herkes (en fazla 10.000) |

Kendin test edeceksen **Internal** seç — inceleme beklemezsin.

Ayrıca: TestFlight uygulamasında **davet edilen Apple kimliğiyle** oturum
açtığından emin ol. Farklı bir Apple ID ile girildiğinde uygulama listede
hiç görünmez.

### 4. "Beta Sözleşmesi eksik" (422 BETA_CONTRACT_MISSING)

Codemagic derlemesi şu hatayla düşüyordu:

```
POST /v1/betaAppReviewSubmissions -> 422
Uygulama için beta sözleşmesi eksik.
```

**İki ayrı mesele birbirine karışmıştı.**

**a) Gereksiz inceleme gönderimi — düzeltildi.**
Beta App Review yalnızca **dış (external)** test kullanıcıları için gerekli.
Liqra'da sadece `Liqra Test` adlı **iç (internal)** grup var; iç kullanıcılar
incelemeyi beklemeden yükler. `submit_to_testflight: false` yapıldı —
`beta_groups` dağıtımı ayrı bir adımda zaten çalışıyor (log'da yapının gruba
eklendiği görülüyor). Dış grup eklenirse tekrar `true` yapılmalı.

**b) Sözleşme durumu — hesapta kontrol edilmeli.**
Apple, TestFlight dağıtımı için **yalnızca iç test yapılsa bile** Paid Apps
Agreement'ın gerçekten yürürlükte olmasını istiyor. "Active" görünmesi yetmez;
arkasındaki üç şey de tamam olmalı:

> App Store Connect → **Business** (Anlaşmalar, Vergi ve Bankacılık)

| Alan | Ne olmalı |
|---|---|
| Free Apps Agreement | Active |
| Paid Apps Agreement | Active |
| **Bank Accounts** | Banka hesabı ekli ve Active |
| **Tax Forms** | Türkiye + **ABD (W-8BEN)** formları gönderilmiş |

Vergi formları eksikken sözleşme "Active" görünebilir ama Apple'ın arka ucu
beta sözleşmesini yok sayar — hem bu 422 hatası hem de telefonda
**"İstenilen uygulama kullanılamıyor veya yok"** buradan gelir.

Paid Apps Agreement yeni imzalandıysa (Liqra'da 8 Eylül 2026) Apple'ın arka
ucunun eşitlenmesi **48 saate kadar** sürebiliyor. Formlar tamsa ve süre
geçtiyse sorun Apple tarafındadır; bilinen bir arka uç arızası:

- Feedback Assistant üzerinden bildir (e-postadan daha hızlı dönüyor)
- Başlık: `TestFlight betaAppReviewSubmissions returns 422 BETA_CONTRACT_MISSING`
- Bundle ID ve hatalı isteğin zamanını yaz

### 5. TestFlight beklerken: Ad Hoc ile test et

Beta contract arızası çözülene kadar (1-3 hafta sürebiliyor) uygulamayı
TestFlight'sız da telefona kurabilirsin. Ad Hoc dağıtımın beta sözleşmesiyle
ilgisi yoktur, arızadan etkilenmez. Mac gerekmez.

`ios-adhoc` iş akışı `codemagic.yaml` içinde hazır.
Adım adım anlatım: **`docs/adhoc-kurulum.md`**

### 6. Apple inceleme test hesabı

App Store incelemesi giriş isteyen her uygulamada **çalışan bir test hesabı**
zorunlu tutar. Uygulama içinden bir hesap aç, içine birkaç örnek işlem gir ve
bilgilerini App Store Connect → App Review Information alanına yaz.

Boş bir hesapla gönderirsen "uygulamanın ne yaptığını göremedik" gerekçesiyle
reddedilme ihtimali yüksek.

### 7. Cloud Functions deploy

Düzeltilen haber kaynakları, kampanya temizliği ve ASCII slug'lar **hâlâ
yayında değil**. Uygulama canlıya çıkarsa kullanıcılar eski (üçü ölü) RSS
kaynaklarıyla karşılaşır.

```bash
cd functions && firebase deploy --only functions
```

Blaze planı gerekli — Cloud Functions ücretsiz planda dışarı ağ isteği
yapamaz.

### 8. Mağaza görselleri ve metinleri

| Öğe | Gereken |
|---|---|
| Uygulama ikonu | 512×512 (Play) · 1024×1024 (App Store) |
| Ekran görüntüleri | Play: en az 2 telefon · Apple: 6.7" ve 6.5" zorunlu |
| Feature graphic | 1024×500 (yalnızca Play) |
| Kısa açıklama | 80 karakter (Play) |
| Uzun açıklama | 4000 karakter (Play) · Apple: alt başlık + açıklama |

iPad ekran görüntüsü **gerekmiyor** — uygulama iPhone-only olarak beyan
ediliyor.

### 9. Mağaza formları

- Play → **Veri Güvenliği** formu (aşağıdaki hazır bilgi)
- Play → **İçerik derecelendirmesi** anketi
- Apple → **Gizlilik etiketleri**
- Apple → **Yaş sınırı**
- Her ikisi → **Finans** kategorisi

---

## 📋 Mağaza formları için hazır bilgi

### Uygulama kimliği
- **Paket adı / Bundle ID:** `com.emrec.muhasebe`
- **Sürüm:** 1.1.0 (build numarasını CI otomatik artırır)
- **Kategori:** Finans
- **Minimum sürüm:** Android 6.0 (API 23) · iOS 15.0
- **Cihaz:** yalnızca iPhone (iPad desteklenmiyor)

### İzinler ve gerekçeleri

| İzin | Neden |
|---|---|
| `CAMERA` | Fiş/fatura tarama (OCR) |
| `POST_NOTIFICATIONS` | Ekstre ve bütçe hatırlatmaları |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Firestore ve piyasa verisi |
| `NSLocationWhenInUse` (iOS) | **Kullanılmıyor** — yalnızca bağımlı bir SDK'nın referansı yüzünden amaç metni tanımlı |

### Veri Güvenliği / Gizlilik etiketleri

Toplanan veri türleri:

- **Kişisel bilgi:** e-posta (kimlik doğrulama)
- **Finansal bilgi:** kullanıcının elle girdiği işlem, bakiye, borç, portföy
- **Uygulama etkinliği:** çökme raporu, ekran görüntüleme (Analytics)
- **Cihaz kimliği:** FCM bildirim token'ı

Beyan edilecekler:

- Veri **şifreli** aktarılıyor (HTTPS) — ✅
- Kullanıcı **silme** talep edebiliyor — ✅ Profil → Hesabı Sil
- Veri **satılmıyor / reklamla paylaşılmıyor** — ✅
- **İzleme için kullanılmıyor** — ✅
- Veri kullanıcıya **bağlı** — ✅

⚠️ **Banka bağlantısı olmadığını açıkça belirt.** Finans kategorisinde "banka
verisi" beyanı ek doğrulama süreci başlatır; Liqra'da bankaya bağlanma yok,
tüm veriyi kullanıcı elle giriyor.

---

## 🚀 Yayın akışı

Yerelde derleme **yapılmıyor**: bu makinede Android SDK ve Xcode yok, Firebase
yapılandırma dosyaları da depoda değil. Her şey Codemagic üzerinden çıkıyor.

| İş akışı | Ne yapar | Nereye gider |
|---|---|---|
| `quality-check` | Her push'ta analyze + test | — |
| `android-release` | `.aab` üretir | Play → **internal** kanal, taslak |
| `ios-release` | `.ipa` üretir | **TestFlight** |

İkisi de **doğrudan üretime göndermiyor**. App Store incelemesine ve Play
üretim kanalına geçiş elle yapılacak.

---

## ⏳ Yayına engel olmayanlar

| İş | Not |
|---|---|
| Erişilebilirlik | Kod tabanında hiç `Semantics` etiketi yok; ekran okuyucu deneyimi zayıf |
| Kampanya verisi | Tamamı örnek (`isSample: true`); canlı banka kaynağı bağlı değil |
| Fon fiyatları | TEFAS fiyat ucu kapalı; kullanıcı elle giriyor |
| CollectAPI kullanımı | `fetchMarketData` 7/24 2 dakikada bir çalışıyor; borsa saati kontrolü yok |
