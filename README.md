# Liqra — Kişisel Finans & Yatırım Asistanı

Flutter tabanlı mobil uygulama: harcama takibi, banka/kredi kartı yönetimi,
çok varlıklı portföy takibi, Gemini destekli AI finans asistanı, Türk banka
kampanyaları ve piyasa haberleri.

- **Firebase projesi:** `finansasistaniapp`
- **Android namespace:** `com.emrec.muhasebe`
- **Min SDK:** 23 (Firebase Messaging gereği)
- **Flutter:** 3.44+ ile test edildi

Mimari, veri akışı ve modül yapısı için [CLAUDE.md](CLAUDE.md) dosyasına bakın.

## Kurulum

```bash
flutter pub get
```

Ardından Firebase yapılandırma dosyasını ekleyin — repoda **bulunmaz**
(`.gitignore`'da):

```
android/app/google-services.json
```

`flutterfire configure` ile yeniden üretebilirsiniz.

### API anahtarları

| Anahtar | Nerede tanımlanır |
|---|---|
| `gemini_api_key` | Firebase Remote Config |
| `collectapi_key` | Firebase Remote Config veya `--dart-define=COLLECT_API_KEY=...` |
| `COLLECT_API_KEY` | Cloud Functions — `firebase functions:secrets:set COLLECT_API_KEY` |

## Çalıştırma

```bash
flutter run -d <device-id>
```

`android/key.properties` yoksa release build debug anahtarıyla imzalanır;
uygulama yine de derlenir.

## Kod üretimi

Model, state veya freezed sınıfı değiştiğinde zorunlu:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Test ve statik analiz

```bash
flutter analyze
flutter test
```

## Build

```bash
flutter build apk --release
flutter build appbundle
```

Release imzalama için `android/key.properties`:

```properties
storeFile=../liqra-release.jks
storePassword=...
keyAlias=liqra
keyPassword=...
```

## Cloud Functions

```bash
cd functions
firebase deploy --only functions
firebase emulators:start --only functions
```

Deploy edilen fonksiyonlar `functions/src/index.js` içinde export edilenlerdir:
`fetchMarketData`, `fetchCampaigns`, `fetchNews`, `onUserCreated`.

## Node.js backend (`/backend`)

Express + Anthropic SDK + PostgreSQL. **Flutter uygulaması tarafından şu an
kullanılmıyor**; ileride sunucu tarafı AI ve analitik için tutuluyor.

```bash
cd backend
npm run dev
npm test
```

## Bilinen sınırlamalar

- **Web hedefi desteklenmiyor.** `firebase_options.dart` web için üretilmemiş
  ve OCR ekranı `dart:io` kullanıyor. Web için `flutterfire configure` ile web
  uygulaması kaydı ve OCR'da koşullu import gerekir.
- `bank_campaigns` koleksiyonundaki seed kayıtları örnek içeriktir; uygulamada
  "Örnek" rozetiyle gösterilir.
