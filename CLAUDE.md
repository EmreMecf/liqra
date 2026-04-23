# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Liqra** — Kişisel Finans & Yatırım Asistanı. Flutter mobil uygulaması; harcama takibi, portföy yönetimi, AI finans asistanı (Gemini 2.0 Flash), Türk banka kampanyaları ve piyasa haberleri.

- Firebase project ID: `finansasistaniapp`
- Android namespace: `com.emrec.muhasebe`
- Min SDK: 23 (Firebase Messaging zorunluluğu)
- Flutter SDK: ^3.8.1

## Commands

```bash
# Bağımlılıkları yükle
flutter pub get

# Kod üretimi — model, state veya DI değişikliğinden sonra ZORUNLU
dart run build_runner build --delete-conflicting-outputs

# Çalıştır
flutter run -d <device-id>

# Build
flutter build apk --release       # key.properties gerektirir
flutter build appbundle            # Google Play
flutter build web                  # build/web/ → Firebase Hosting

# Cloud Functions
cd functions && firebase deploy --only functions
firebase emulators:start --only functions

# Node.js Backend
cd backend && npm run dev          # nodemon
cd backend && npm test             # Jest
```

## Architecture

**Clean Architecture + Feature Modules + Provider pattern.**

```
lib/
├── core/
│   ├── constants/        # app_colors.dart (Material 3 dark, Teal #0AFFE0 + Gold #E4B84A)
│   │                     # app_typography.dart (Fraunces/Outfit/DM Mono 3-font system)
│   ├── di/               # injection.dart — get_it manuel kaydı (8 feature, build_runner yok)
│   ├── error/            # app_exception.dart — freezed sealed union (Server/Network/Cache/Claude/RateLimit)
│   ├── network/          # dio_client.dart — JWT interceptor, rate limiter (20 AI req/saat)
│   ├── services/         # AuthService, FirestoreService, GeminiService, FeatureFlagService,
│   │                     # NotificationService, ClaudeApiService, AnalyticsService, CrashService, PnLService
│   └── utils/            # result.dart (Result<T> = Success|Failure), formatters.dart (TR locale)
├── data/
│   ├── models/           # UserModel, TransactionModel, GoalModel, PortfolioModel, RecurringItemModel
│   └── providers/        # AppProvider — global state (profil, transactions, goals, portfolio)
├── features/             # 8 feature modülü (her biri data/domain/presentation üçlüsüyle)
│   ├── accounts/         # Banka hesabı, kredi kartı, kredi
│   ├── ai_assistant/     # Gemini chat (4 mod: bütçe/portföy/hedef/sohbet)
│   ├── campaigns/        # Banka kampanyaları (Cloud Functions seed data)
│   ├── dashboard/        # Ana sayfa özeti
│   ├── news/             # Finans haberleri (RSS)
│   ├── portfolio/        # Çok varlıklı yatırım takibi
│   ├── spending/         # Harcama ve kategori takibi
│   └── subscriptions/    # Abonelik yönetimi
└── presentation/         # Shared UI + MainScaffold
    ├── auth/             # Login/Register (Email + Google + Apple)
    ├── onboarding/       # İlk açılış intro + profil kurulumu
    ├── kesfet/           # Kampanyalar + haberler
    ├── ocr/              # Fiş tarama (Gemini Vision)
    └── widgets/          # LiqraLogo, AppCard, DeltaChip, AnimatedCounter, PortfolioDonutChart
```

Her feature modülü şu yapıya uyar:
```
features/<feature>/
├── data/
│   ├── datasources/      # Firestore implementasyonu
│   ├── models/           # freezed + json_serializable DTO
│   └── repositories/     # Soyut sözleşme implementasyonu
├── domain/
│   ├── entities/         # Freezed immutable entity
│   ├── repositories/     # Abstract interface
│   └── usecases/
└── presentation/
    ├── viewmodel/        # ChangeNotifier + freezed State (initial/loading/loaded/error)
    ├── screens/
    └── widgets/
```

## State Management & Data Flow

```
Screen/Widget
  ↓ Provider.watch / Consumer
ViewModel (ChangeNotifier + freezed State)
  ↓ Use Cases
Repository Implementation
  ↓ DataSources
Firestore / Remote API
```

- **AppProvider** (`lib/data/providers/app_provider.dart`): global kullanıcı state'i. Auth değiştiğinde `loadUserProfile()` tetiklenir, Firestore stream'leri başlatılır.
- **PortfolioViewModel**: `market/live_prices` Firestore doc'unu dinler, Cloud Functions her 2 dakikada günceller.
- **SpendingViewModel**: aynı ay için 60 saniyelik cache.
- **MainScaffold**: 8 ekranı `_LazyIndexedStack` ile cache'ler.

## Auth Flow

1. Splash → intro bayrağı (SharedPreferences)
2. Intro onboarding (sadece ilk açılış)
3. Firebase Auth stream:
   - Oturum yok → `AuthScreen`
   - Oturum var + profil tamamlanmamış → `OnboardingScreen`
   - Oturum var + profil var → `MainScaffold`

Profil tamamlanma bayrağı: `SharedPreferences` key `profile_complete_{uid}`

## Firebase / Backend

### Firestore Koleksiyonları
```
users/{uid}/
  transactions/, assets/, subscriptions/, accounts/, goals/

market/live_prices           # Cloud Functions her 2dk yazar (read-only Flutter)
tefas_funds/{fundCode}/
bank_campaigns/{docId}/
news/{docId}/
meta/{docId}/                # Son güncelleme timestamp
```

### Cloud Functions (`/functions`, Node 20, Firebase v2)
| Fonksiyon | Kaynak | Hedef |
|---|---|---|
| `fetchMarketData` | Binance, Yahoo Finance, CollectAPI | `market/live_prices` |
| `fetchGoldPrices` | CollectAPI | `market/live_prices` (gold.*) |
| `fetchTefasPrices` | TEFAS API | `tefas_funds/` |
| `fetchCampaigns` | Bank API → RSS → seed data | `bank_campaigns/` |
| `fetchNews` | RSS | `news/` |

`fetchMarketData` 90 saniyelik dedup ile 2 dakikada bir çalışır, `Promise.allSettled` ile fault-tolerant.

### API Key Yönetimi
- **Gemini API key**: Firebase Remote Config (`gemini_api_key`) — güvenli
- **Anthropic API key**: SharedPreferences veya dart-define — kullanıcı yönetimli
- **DioClient base URL**: `http://localhost:3000/api` hardcoded — üretimde .env gerekli

### Firestore Security Rules
- Kullanıcı sadece kendi `users/{uid}/` alt koleksiyonlarını okuyup yazabilir
- `market`, `tefas_funds`, `bank_campaigns`, `news`, `meta` → herkese public read, sadece Cloud Functions yazar

## Core Services

| Servis | Dosya | Notlar |
|---|---|---|
| `AuthService` | `core/services/auth_service.dart` | Email + Google + Apple |
| `FirestoreService` | `core/services/firestore_service.dart` | Offline persistence açık (unlimited cache) |
| `GeminiService` | `core/services/gemini_service.dart` | Gemini 2.0 Flash, Remote Config'den API key |
| `FeatureFlagService` | `core/services/feature_flag_service.dart` | Remote Config — feature toggle + A/B test |
| `ClaudeApiService` | `core/services/claude_api_service.dart` | Anthropic SDK, model hardcoded (TODO: Remote Config) |
| `NotificationService` | `core/services/notification_service.dart` | FCM + flutter_local_notifications |
| `PnLService` | `core/services/pnl_service.dart` | Kar/zarar hesaplama |

## Node.js Backend (`/backend`)

Express.js + Anthropic SDK + PostgreSQL. Şu an Flutter uygulaması tarafından kullanılmıyor; ileride backend-side AI ve analitik için.

Claude chat için 4 sistem prompt modu: `budget_audit`, `portfolio_advisor`, `goal_tracker`, `free_chat`.

Cron job (ayın 1'i, gece yarısı): aylık rapor üretimi — sadece demo kullanıcı için (TODO: tüm kullanıcılar).

## Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

Freezed kullanan kritik sınıflar: `AppException`, `Result<T>`, tüm `*DTO` ve `*Entity` sınıfları, `*State` (SpendingState, PortfolioState, AiAssistantState vb.)

## Localization & Formatting

`formatters.dart` ile Türkçe para birimi (`289.847,50 TL`), yüzde (`+12,4%`), kompakt (`289,8B`).  
`DateFormat` ile `tr_TR` locale import bağımlılığı sorun yaratabilir — `formatters.dart`'taki manuel ay isimlerini kullan (bkz. commit `0ca941b`).

## OCR / Belge Tarama

`OcrScreen` (`lib/presentation/ocr/ocr_screen.dart`) iki modda çalışır:

- **Spending modu** (default): Fiş/fatura → `SpendingViewModel.addTransaction()`. `SpendingScreen`'den açılır.
- **Account modu** (`accountId` + `accountName` parametresi ile): Banka ekstresi → `AccountsViewModel.importStatement()`. `AccountsScreen`'deki 🟡 "Ekstre Yükle" butonu aracılığıyla açılır. Birden fazla hesap varsa önce hesap seçme sheet'i gösterilir.

```dart
// Account modunda açmak:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => OcrScreen(accountId: acc.id, accountName: acc.name),
));
```
