# Liqra — Yayın Kontrol Listesi

Son denetim: 3 Eylül 2026 · `flutter analyze` temiz · 160 test geçiyor

---

## 🔴 Yayına engel — sende

Bunlar olmadan uygulama **derlenmiyor** ya da mağaza **reddediyor**.

### 1. Firebase yapılandırma dosyaları

| Dosya | Nereden | Nereye |
|---|---|---|
| `google-services.json` | Firebase Console → Proje ayarları → Android uygulaması | `android/app/` |
| `GoogleService-Info.plist` | Firebase Console → iOS uygulaması ekle | `ios/Runner/` |

iOS uygulaması Firebase'de **henüz kayıtlı değil** — `firebase_options.dart`
web ve iOS için `UnsupportedError` fırlatıyor. Bundle ID: `com.emrec.muhasebe`

Dosyayı indirdikten sonra:

```bash
flutterfire configure
```

Bu komut `firebase_options.dart` dosyasını iOS için de doldurur.

### 2. Google girişi — iOS URL şeması

`GoogleService-Info.plist` içindeki `REVERSED_CLIENT_ID` değerini
`ios/Runner/Info.plist` içindeki `REVERSED_CLIENT_ID_YER_TUTUCU` yerine yaz.
Biçim: `com.googleusercontent.apps.123456-abcdef`

**Bu olmadan** Google girişi tarayıcıdan geri dönemez, kullanıcı beyaz ekranda
kalır.

### 3. Android imzalama anahtarı

```bash
keytool -genkey -v -keystore liqra-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias liqra
```

Sonra `android/key.properties` oluştur (bu dosya `.gitignore`'da, commit
edilmez):

```
storePassword=...
keyPassword=...
keyAlias=liqra
storeFile=C:/yol/liqra-release.jks
```

⚠️ **Keystore dosyasını kaybetme.** Kaybedersen aynı uygulamayı bir daha
güncelleyemezsin — Play Store yeni paket adı ister.

### 4. Araç zinciri

`flutter doctor` şu an iki eksik gösteriyor:

- **Android SDK yok** → [Android Studio](https://developer.android.com/studio)
  kur, SDK + cmdline-tools bileşenlerini seç
- **Xcode yok** → iOS derlemesi için **Mac zorunlu**. Mac'in yoksa
  [Codemagic](https://codemagic.io) veya GitHub Actions macOS runner
  kullanabilirsin

### 5. Gizlilik politikası URL'si

`docs/gizlilik-politikasi.md` hazır ama **herkese açık bir adreste
yayınlanmalı**. En kolayı GitHub Pages:

Repo → Settings → Pages → Source: main / docs → adres:
`https://emremecf.github.io/liqra/gizlilik-politikasi`

Bu URL hem Play Console'a hem App Store Connect'e girilecek. İkisi de
zorunlu tutuyor.

---

## ✅ Bu turda düzeltilenler

### iOS — çökme sebepleri giderildi

`Info.plist` Flutter şablonundan kalmıştı, hiç hazırlanmamıştı:

| Eksik | Sonucu |
|---|---|
| `NSCameraUsageDescription` | Fiş tarama açılınca **uygulama çöküyordu** |
| `NSPhotoLibraryUsageDescription` | Galeriden seçince **çöküyordu** |
| Görünen ad "Muhasebe" | Ana ekranda Liqra yerine "Muhasebe" yazacaktı |
| `UIBackgroundModes` yok | Bildirimler uygulama kapalıyken gelmiyordu |
| `ITSAppUsesNonExemptEncryption` yok | Her yüklemede Apple manuel soruyordu |
| Yatay yön açık | Açılış karesi yatay çizilip zıplıyordu |

iOS izin metinleri Türkçe ve amacı açık yazıldı — "erişim gerekiyor" gibi
genel ifadeler App Store reddi sebebidir.

### iOS — dağıtım hedefi

`IPHONEOS_DEPLOYMENT_TARGET` 12.0 idi. `firebase_core 3.x` **iOS 13**
istiyor; 12.0 ile `pod install` başarısız olurdu. 13.0'a çekildi (3 yapılandırmada).

### iOS — yetkiler

`Runner.entitlements` yoktu, oluşturuldu ve projeye bağlandı:

- `aps-environment` — FCM bildirimleri
- `com.apple.developer.applesignin` — **App Store yönergesi 4.8 gereği
  zorunlu**: Google ile giriş sunan uygulama Apple ile girişi de sunmak
  zorunda. Eksikse yükleme reddedilir.

### Android — finansal veri yedeğe çıkıyordu

`allowBackup` varsayılan olarak `true` idi: hesap bakiyeleri, kart borçları ve
işlem geçmişi Google Drive yedeğine kopyalanıyordu. Veri zaten Firestore'da
kullanıcının hesabında ve yeni cihazda girişle geri geliyor — yedek yalnızca
saldırı yüzeyi büyütüyordu.

`allowBackup="false"` + `backup_rules.xml` + `data_extraction_rules.xml`
(Android 12+ için ayrı dosya gerekiyor).

---

## 📋 Mağaza formları için hazır bilgi

### Uygulama kimliği
- **Paket adı / Bundle ID:** `com.emrec.muhasebe`
- **Sürüm:** 1.1.0 (versionCode 2)
- **Kategori:** Finans
- **Minimum sürüm:** Android 6.0 (API 23) · iOS 13.0

### İzinler ve gerekçeleri

| İzin | Neden |
|---|---|
| `CAMERA` | Fiş/fatura tarama (OCR) |
| `POST_NOTIFICATIONS` | Ekstre ve bütçe hatırlatmaları |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Firestore ve piyasa verisi |

### Google Play — Veri Güvenliği formu

Toplanan veri türleri:

- **Kişisel bilgi:** e-posta (kimlik doğrulama)
- **Finansal bilgi:** kullanıcının elle girdiği işlem, bakiye, borç, portföy
- **Uygulama etkinliği:** çökme raporu, ekran görüntüleme (Analytics)
- **Cihaz kimliği:** FCM bildirim token'ı

Beyan edilecekler:
- Veri **şifreli** aktarılıyor (HTTPS) — ✅
- Kullanıcı **silme** talep edebiliyor — ✅ (Profil → Hesabı Sil)
- Veri **satılmıyor / reklamla paylaşılmıyor** — ✅

⚠️ **Banka bağlantısı olmadığını** açıkça belirt. Finans kategorisinde
"banka verisi" beyanı ek doğrulama süreci başlatır; Liqra'da kullanıcının
elle girdiği veriler var, bankaya bağlanma yok.

### App Store — Gizlilik etiketleri

Aynı liste. Ek olarak "Veri kullanıcıya bağlı mı?" → **Evet** (hesabına bağlı).
"İzleme için kullanılıyor mu?" → **Hayır**.

---

## ⏳ Kalan işler (yayına engel değil)

| İş | Not |
|---|---|
| Mağaza görselleri | Ekran görüntüleri, feature graphic (1024×500), ikon 512×512 |
| Uygulama açıklaması | Play: 80 karakter kısa + 4000 uzun; Apple: alt başlık + açıklama |
| Test hesabı | Apple inceleme ekibi için giriş bilgisi (zorunlu) |
| Cloud Functions deploy | Düzeltilen haber kaynakları hâlâ yayında değil |
| Erişilebilirlik | Kod tabanında hiç `Semantics` etiketi yok |
| Yaş sınırı formu | Her iki mağazada da doldurulacak |

---

## 🚀 Yayın komutları

Yukarıdaki engeller çözüldükten sonra:

```bash
flutter build appbundle --release
```

```bash
flutter build ipa --release
```

`.aab` dosyası: `build/app/outputs/bundle/release/app-release.aab`
`.ipa` dosyası: `build/ios/ipa/`
