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
│   │                     # NotificationService, NotificationPreferences,
│   │                     # AnalyticsService, CrashService
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

Deploy edilenler = `functions/src/index.js` içinde export edilenler:

| Fonksiyon | Zamanlama | Kaynak | Hedef |
|---|---|---|---|
| `fetchMarketData` | 2 dk | Binance (kripto), CollectAPI (döviz+altın+BIST) | `market/live_prices` |
| `fetchTefasFunds` | Günlük 19:30 | TEFAS `/api/fund-returns/export` | `tefas_funds/catalog` |
| `fetchCampaigns` | Günlük 03:00 | Banka API → seed data | `bank_campaigns/` |
| `fetchNews` | Saatlik | RSS (5 kaynak) | `news/` |
| `onUserCreated` | Firestore trigger | `users/{uid}` create | `role: 'personal'` claim |

`fetchMarketData` 90 saniyelik dedup ile çalışır, `Promise.allSettled` ile fault-tolerant.
Altın ve fon verisi ayrı fonksiyonlarda değil, `sources/collectapi.js` ve
`sources/tefas.js` içinde `fetchMarketData` altında toplanmıştır.

`fetchGoldPrices.js`, `fetchTefasPrices.js` ve `fetchMarketPrices.js` **silindi**:
deploy edilmiyorlardı ama aynı `market/live_prices` dökümanına yazıyorlardı —
yanlışlıkla export edilirlerse çalışan veriyi ezerlerdi.

`sources/collectapi_stocks.js` eskiden `yahoo.js` adındaydı; **Yahoo Finance
kullanılmıyor**, BIST verisi CollectAPI `/economy/hisseSenedi` ucundan gelir.

### TEFAS Fon Verisi (ÖNEMLİ)

TEFAS'ın eski public API'si (`POST /api/DB/BindHistoryInfo`) **kapatıldı** —
gerçek tarayıcıda bile `404 ERR-006 "Method not found or disabled!"` döner ve
site bot koruması arkasındadır.

Yeni kaynak (kimlik doğrulaması/çerez/bot koruması yok, sunucudan çağrılabilir):

```
POST https://www.tefas.gov.tr/api/fund-returns/export
{"format":"json","listingType":"return","fundType":"YAT","locale":"tr"}
```
`fundType`: `YAT` (2137) · `EMK` (400) · `BYF` (37) → toplam ~2574 fon
`listingType`: `return` | `management` | `operatingExpense` | `size`

Dönen alanlar: `fonKodu`, `fonUnvan`, `fonTurAciklama`, `riskDegeri`.

**Birim pay değeri (fiyat) bu uçta YOKTUR** — fiyat yalnızca
`/tr/fon-detayli-analiz/{KOD}` sayfasının server-render çıktısında bulunur ve o
sayfalar bot koruması arkasındadır. Bu nedenle:

- Fon **arama/seçme** çalışır (katalog `tefas_funds/catalog`, tek doküman ~315 KB)
- Fon **fiyatı kullanıcı tarafından elle girilir** (`AddAssetSheet`)
- `market/live_prices.funds` **yazılmaz**; `PortfolioViewModel._resolvePrice`
  fon için 0 döner ve kullanıcının girdiği fiyat korunur
- `getiri1a/1y…` alanları uçta var ama daima `null` → "En İyi Fonlar" listesi
  gerçek getiri verisi olmadan boş döner (uydurma sıralama yapılmaz)

### API Key Yönetimi
- **Gemini API key**: Firebase Remote Config (`gemini_api_key`). Anahtar
  **istemciye iner** — paketi açan çıkarabilir; saatlik 20 istek sınırı da
  yalnızca istemcide. Google Cloud'da API kısıtlaması + bütçe alarmı şart;
  kalıcı çözüm Firebase AI Logic + App Check.
- **Gemini ÜCRETLİ katmanda olmalı.** Anahtarın bağlı olduğu Cloud projesinde
  faturalandırma açık değilse Google gönderilen içeriği ürün geliştirmede
  kullanır ve insan incelemeciler okuyabilir; şartlar ücretsiz katmana kişisel
  veri göndermeyi yasaklıyor. Liqra finansal özet ve banka ekstresi PDF'i
  gönderiyor. Gizlilik politikası ücretli katmanı varsayar.
- **Anthropic API key**: SharedPreferences veya dart-define — kullanıcı yönetimli
- **DioClient base URL**: `--dart-define=API_BASE_URL=...` ile override edilir,
  varsayılan `http://localhost:3000/api`. Uygulama şu an backend'i kullanmıyor.
- AI için tek yol: `GeminiService`. Kullanılmayan `ClaudeApiService`,
  `PnlService` ve `PerformanceService` silindi.

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
| `NotificationService` | `core/services/notification_service.dart` | FCM + yerel bildirim gösterimi |
| `NotificationPreferences` | `core/services/notification_preferences.dart` | Kullanıcının bildirim açma/kapama tercihleri |

## Node.js Backend (`/backend`)

Express.js + Anthropic SDK + PostgreSQL. Şu an Flutter uygulaması tarafından kullanılmıyor; ileride backend-side AI ve analitik için.

Claude chat için 4 sistem prompt modu: `budget_audit`, `portfolio_advisor`, `goal_tracker`, `free_chat`.

Cron job (ayın 1'i, gece yarısı): `fcmToken` alanı olan **tüm** kullanıcılar için
bir önceki ayın raporunu üretir ve FCM bildirimi gönderir.

Kimlik doğrulaması: `ai`, `ocr`, `portfolio`, `notifications` uçları
`verifyToken` middleware'i arkasındadır; `market` ve `tefas` herkese açıktır.

## Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

Freezed kullanan kritik sınıflar: `AppException`, `Result<T>`, tüm `*DTO` ve `*Entity` sınıfları, `*State` (SpendingState, PortfolioState, AiAssistantState vb.)

## Muhasebe Sözleşmesi (ÖNEMLİ)

Her para hareketi bir **akış tipi** (`MoneyFlow`) taşır. Gelir/gider/nakit
hesaplarının TEK kaynağı budur — ham `type` string'ine asla bakılmaz.

| flow | Nakit | Gider mi | Örnek |
|---|---|---|---|
| `income` | +| hayır | Maaş |
| `expense` | − | **evet** | Nakit/banka kartıyla market |
| `cardExpense` | 0 | **evet** | Kredi kartıyla market (tahakkuk) |
| `cardPayment` | − | hayır | Ekstre ödemesi — borç kapatma |
| `transfer` | 0 | hayır | Hesaplar arası |
| `investment` | − | hayır | Midas'a EFT, IBAN'la altın |
| `loanPayment` | − | **evet** | Kredi taksidi |

**Muhasebe esası: TAHAKKUK.** Kart harcaması ödeme anında değil satın alma
anında gider yazılır.

```dart
if (tx.isExpense) ...   // flow.countsAsExpense — TEK gider tanımı
tx.cashEffect           // nakit etkisi (kart harcaması 0 döner)
```

Kurallar:
- **Yeni gider hesaplayıcısı yazma.** `isExpense` / `expensesForMonth` kullan.
  Eskiden beş farklı tanım vardı, aynı ay için farklı toplamlar çıkıyordu.
- **Yatırım gider değildir.** Portföye varlık eklemek otomatik gider kaydı
  ÜRETMEZ; kullanıcı "hesabımdan çıkış olarak kaydet" derse `investment`
  akışıyla yazılır. Aksi hâlde Midas'a EFT + varlık ekleme çift sayılır.
- **Eski kayıtlarda `flow` yoktur** — `MoneyFlowParser.parse()` bunu
  `type` + `category`'den türetir (`category == 'yatirim'` → `investment`).
  Migration gerekmez.
- Hedef birikimi = `manualAmount` (elle eklenen) + portföy değeri.
  `syncGoalWithPortfolio` yalnızca portföy bileşenini günceller; eskiden
  `currentAmount`'ı eziyordu ve elle eklenen birikimi siliyordu.

## Kredi Kartı Ekstre Döngüsü (ÖNEMLİ)

Kart tarihlerinin TEK kaynağı `BillingCycle`
(`features/accounts/domain/billing_cycle.dart`). **Entity içinde veya widget'ta
satır içi tarih hesabı yazma.**

```dart
card.cycle.lastClosingDate   // kapanmış son ekstrenin kesim tarihi
card.cycle.currentDueDate    // şu an ödenmesi gereken ekstre — GEÇMİŞTE olabilir
card.nextPaymentDueDate      // bugün dahil ilk ödeme tarihi
card.daysUntilDue            // bugün son gün ise 0
card.isOverdue               // ekstre borcu var VE son ödeme tarihi geçti
```

Üç tuzak `BillingCycle` içinde kapatıldı — elle yazınca geri gelirler:

- `DateTime(y, 2, 31)` hata vermez, **3 Mart'a taşar**. `BillingCycle.dayInMonth`
  ayın son gününe sabitler.
- Gece yarısı kurulan tarihi saat taşıyan `DateTime.now()` ile karşılaştırmak
  ödemenin son gününü "geçmiş" gösterir. Tüm tarihler `dateOnly` ile normalize
  edilir.
- Son ödeme tarihi hep ileri üretilirse gecikme tespit edilemez. Bu yüzden
  "şu anki ekstrenin vadesi" (`currentDueDate`) ile "bir sonraki ödeme"
  (`nextDueDate`) ayrı modellenir.

Aynı mantık `LoanEntity` için de geçerlidir; kredide gecikme `lastPaymentDate`
alanına bakılarak belirlenir.

### Ekstre otomatik kesilir

`StatementRollover` kesim günü geçmiş kartların ekstresini `AccountsViewModel.load()`
sırasında oluşturur:

```
yeniEkstre = usedAmount − (kesim tarihinden sonraki kart harcamaları)
asgari     = yeniEkstre × 0.20
```

Karta yazılan `statementClosedAt` işlemi **idempotent** yapar — uygulama günde
on kez açılsa da ekstre bir kez kesilir. Ekstreyi elle güncelleyen her yol
(`updateStatement`, `updateCreditCardBalance`) bu alanı damgalamak zorundadır,
aksi hâlde devir kullanıcının girdiği değeri ezer.

Formül elle girilen açılış bakiyesiyle de çalışır: kart eklenirken yazılan borcun
arkasında işlem kaydı olmasa bile `usedAmount` içinde durur ve ilk kesimde
ekstreye geçer.

### Kart toplamları

| Getter | Anlamı |
|---|---|
| `totalCreditUsed` | Kartların TOPLAM borcu |
| `totalStatementDebt` | Yalnızca kesilmiş ekstreler |
| `totalUnbilled` | Kesim sonrası, henüz faturalanmamış harcama |
| `creditUtilization` | `totalCreditUsed / totalCreditLimit` |
| `netWorth` | `totalBankBalance − totalCreditUsed` |

- **Kullanım oranı ortalama DEĞİLDİR.** Kartların `usagePercent` değerlerinin
  ortalamasını alma; 100.000 limitli boş bir kart, 1.000 limitli dolu bir kartla
  eşit ağırlık taşımamalı.
- **Net servetten toplam borç düşülür**, ekstre borcu değil. Kesimden sonra
  yapılan harcamalar da borçtur.

### Taksit

`InstallmentPlan.build()` alışverişi aylara böler; taksitlerin toplamı **daima**
satın alma tutarına eşittir (artan kuruşlar ilk taksite eklenir).
`recordInstallmentPurchase` her taksiti kendi ayının tarihiyle ayrı bir hareket
olarak yazar, kart borcunu ise tek seferde toplam tutar kadar artırır —
limit satın alma anında bloke olur.

Geleceğe tarihli taksitler ekstre devriyle uyumludur: henüz gelmemiş taksitler
"kesim sonrası harcama" sayıldığı için o ayki ekstreye yalnızca vadesi gelen
taksit girer.

## AI Asistan (ÖNEMLİ)

Asistan bir sohbet botu değil, kullanıcının **tüm finansal durumunu gören**
bir yardımcıdır. `features/ai_assistant/domain/` altında dört katman vardır:

| Dosya | Sorumluluk |
|---|---|
| `assistant_context.dart` | Asistanın bildiği her şey — saf veri + prompt bloğu |
| `assistant_insight.dart` | `InsightEngine` — proaktif bulgular, **AI çağrısı yok** |
| `campaign_matcher.dart` | Harcama → kampanya eşleştirme, **AI çağrısı yok** |
| `savings_plan.dart` | Birikim planı matematiği, **AI çağrısı yok** |
| `assistant_prompts.dart` | Kimlik + görev promptları |

### Temel kural: model YORUMLAR, HESAPLAMAZ

Tüm rakamlar bağlam bloğunda hazır gelir. "Ayda kaç lira biriktirmeliyim",
"ekstren kaç gün sonra", "market harcaman ne kadar arttı" gibi sorular
**aritmetiktir** — modele sordurulursa yanlış toplama ihtimali her zaman vardır
ve kullanıcı o rakama göre para harcar.

```dart
// ✅ Hesap kodda, anlatım modelde
final plan = SavingsPlanBuilder.build(...);   // rakamlar kesin
AssistantPrompts.savingsPlan(plan, ctx);      // model yalnızca anlatır

// ❌ Modelden hesap isteme
'Hedefine ulaşmak için ayda ne kadar biriktirmeli?'
```

`AssistantPrompts.persona` içindeki sayı kuralları bunu modele de dayatır:
bağlamda olmayan rakam uydurulmaz, bilanço/F-K/ciro gibi finansal tablo
verileri **sayıyla söylenmez**.

### Bağlam nasıl kurulur

`AssistantContextBuilder.fromContext(context)` — altı ViewModel'i tek yapıya
toplar (cüzdan, harcama, portföy, piyasa, haber, kampanya). Yüklenmemiş bölüm
boş kalır, asistan "bu veri yok" der.

`CampaignViewModel` ve `NewsViewModel` bu yüzden **uygulama kökünde** sağlanır
ve DI'da tekildir. Keşfet ekranında yeniden oluşturulursa asistan boş bir kopya
okur.

Bağlama giren piyasa satırları filtrelenir: önce kullanıcının tuttuğu varlıklar,
sonra ana göstergeler. Tüm piyasayı göndermek token israfıdır.

### İçgörüler ve bildirimler

`InsightEngine.analyze(ctx)` gecikmiş kart, ödeme gücü açığı, kategori
sıçraması, abonelik yükü, portföy yoğunlaşması, atıl nakit gibi bulguları
üretir. `AssistantNotifier` bunlardan `notify: true` olanları bildirime çevirir:

- Aynı `id` için **günde bir kez** bildirim (SharedPreferences ile damgalanır)
- Günde en fazla `maxPerDay` (3) bildirim, aciliyet sırasına göre

İçgörüler `main.dart` içinde veriler yüklendikten sonra bir kez üretilir
(`_refreshAssistant`). Ağ isteği yapmaz, maliyeti yoktur.

### Yatırım uyarısı (yasal)

Türkiye'de kişiye özel yatırım danışmanlığı **SPK lisansı** gerektirir
(6362 sayılı Kanun). Liqra lisanslı değildir; asistanın yatırım içeriği
bilgilendirme amaçlıdır.

- `InvestmentDisclaimer` (`presentation/widgets/investment_disclaimer.dart`)
  asistanın ürettiği **her yatırım içeriğinin altında** görünür olmalı —
  şu an hisse analizi sayfası ve asistan sohbet ekranı. Yeni bir yatırım
  analizi ekranı eklenirse oraya da konur.
- Uyarı kaydırılan içeriğin **dışında** durur; uzun bir analizin sonuna
  gömülürse kimse görmez.
- Hisse prompt'u kesin "al / sat / tut" talimatını ve hedef fiyatı yasaklar.
- Arayüz metinlerinde "tavsiye" yerine "analiz" denir. Tanıtım ekranı eskiden
  "yapay zeka destekli tavsiyeler al" diyordu.

`test/investment_disclaimer_test.dart` hem metnin hem prompt kuralının
kaybolmasını yakalar.

### Hisse analizi ve eksik veri

`AnalyzeStockUseCase` şunları birleştirir: canlı fiyat + gün içi aralık + hacim,
o şirketle ilgili **kod tarafında filtrelenmiş** haberler, kullanıcının pozisyonu
ve portföy ağırlığı, risk profili, serbest nakit.

**Bilanço verisi uygulamada YOKTUR.** CollectAPI `/economy/hisseSenedi` yalnızca
fiyat, hacim ve gün aralığı verir; KAP/finansal tablo beslemesi bağlı değildir.
Prompt bu yüzden modele F/K, ciro, kâr, temettü verimi gibi rakamları **sayıyla
söylemeyi yasaklar**; şirket/sektör yorumu niteliksel kalır. Gerçek bilanço
analizi istenirse önce bir finansal tablo kaynağı eklenmelidir.

## Haber ve Kampanya Hattı (ÖNEMLİ)

### Kategori slug'ları ASCII yazılır

Cloud Functions Firestore'a **daima ASCII slug** yazar (`alisveris`, `doviz`,
`sirket`) — istemcideki enum adlarıyla birebir aynı. Okuma tarafı
`normalizeCategorySlug()` kullanır; Türkçe karakterli eski kayıtları da tanır,
migration gerekmez.

```dart
CampaignCategory.fromString('alisveris')  // ✅
CampaignCategory.fromString('alışveriş')  // ✅ eski kayıt
```

Eskiden `switch` yalnızca `'alışveriş'` ile eşleşiyordu ama Firestore'da
`'alisveris'` duruyordu: **tüm alışveriş kampanyaları `diger`e düşüyordu**,
kategori filtresi ve asistan eşleştirmesi çalışmıyordu.

### Kampanyaların tamamı ÖRNEK veridir

Bağlı bir canlı banka kaynağı yok. Denenen ve çalışmayan uçlar
(2026-09-02'de doğrulandı):

| Uç | Sonuç |
|---|---|
| `garantibbva.com.tr/api/v1/campaigns` | 404 |
| `garantibbva.com.tr/kampanyalar.json` | 200 ama AEM sayfa metadatası, kampanya yok |
| `kampanyalar.infinity.json` | yalnızca `.0.json` işaretçisi — derinlik kapalı |

Bu yüzden her kayıt `isSample: true` damgalanır ve:

- Arayüz "Örnek" rozeti gösterir
- **`CampaignMatcher.toInsights` bunları bildirime çevirmez** — uydurma bir
  kampanya için telefona bildirim göndermek kullanıcıyı olmayan bir teklife
  göre harcamaya yöneltir
- `CampaignOffer.promptLine` modele "[ÖRNEK İÇERİK — doğrulanmamış]" der

Canlı kaynak bağlandığında `isSample: false` yazmak yeterlidir; bildirim ve
prompt davranışı kendiliğinden değişir.

`fetchCampaigns` artık **kaynakta olmayan kampanyaları siler** (`removeStale`).
Eskiden yalnızca upsert vardı; seed'den çıkarılan kampanya Firestore'da sonsuza
kadar kalıyordu.

### RSS kaynakları doğrulanmalı

Kaynaklar sessizce ölür. `parseFeed` hatayı yutuyordu, bu yüzden **beş
kaynaktan üçü aylarca 404 verdiği hâlde** haber akışı %40 kapasiteyle çalışıyor
ve logda iz bırakmıyordu. Kaldırılanlar: Mynet Finans, Dünya Gazetesi,
Para Analiz. Eklenenler: TRT Haber Ekonomi, NTV Ekonomi, Hürriyet Ekonomi.

Artık çalışmayan kaynak sayısı hem log'a hem `meta/news` dokümanına yazılır
(`activeFeeds`, `totalFeeds`, `failedFeeds`).

### Haber doküman ID'si bağlantının hash'idir

```js
makeId(slug, link, title) // md5(link).slice(0,16)
```

Eski yöntem URL'nin son path parçasını 40 karaktere kırpıyordu. Ayırt edici
sayısal id slug'ın **sonunda** olduğu için kırpılıyor ve benzer başlıklı iki
haber aynı dokümanı eziyordu. `Date.now()` fallback'i ise aynı haberi her saat
yeni bir id ile yazıp koleksiyonu şişiriyordu.

**Tarihi bilinmeyen haber:** `pubDate` alanı yazılmaz, mevcut kayıttaki tarih
korunur; doküman yeniyse bir kez `now` damgalanır (`stampMissingDates`).
Eskiden her turda `now` yazılıyordu — haber listenin tepesine yapışıyor ve
7 günlük temizliğe hiç takılmıyordu.

## Bütçe Limitleri

Kategori bazlı aylık limitler `users/{uid}/settings/budgets` altında **tek
dokümanda** map olarak tutulur — kategori sayısı sabit ve küçük (12), alt
koleksiyon her açılışta 12 okuma demek olurdu.

```dart
provider.budget.limitFor(TransactionCategory.market)  // 5000 | null
provider.budgetStatus                                 // bu ayın durumu
provider.overBudget                                   // aşılan kategoriler
await provider.setBudgetLimit(category, 5000);        // null/0 → limiti kaldırır
```

Anahtar **daima kanonik slug**'dır (`market`, `yemeicme`). `BudgetModel.fromMap`
eski Türkçe etiketli kayıtları da slug'a çevirir.

- Limiti olmayan kategori "sınırsız" sayılır — kullanıcı her kalem için rakam
  girmeye zorlanmaz.
- `BudgetStatus.ratio` gösterge çubuğu için 0–1 arasına kırpılır; aşımı görmek
  için `rawRatio` veya `isOver` kullan.
- Aşım `InsightEngine` üzerinden bildirime dönüşür (`budget_over_*`), limite
  yaklaşma yalnızca uygulama içinde gösterilir (`budget_near_*`).

## Bildirimler

Bildirimlerin **tamamı** `AssistantNotifier` üzerinden gider. `NotificationService`
yalnızca gösterim katmanıdır; içinde bildirim türü tanımı yoktur.

Üç kural birlikte çalışır:

| Kural | Yer |
|---|---|
| Aynı `id` günde bir kez | `AssistantNotifier` (SharedPreferences damgası) |
| Günde en fazla 3 bildirim | `AssistantNotifier.maxPerDay` |
| Kullanıcı tercihi kapalıysa gönderme | `NotificationPreferences` |

`NotificationPreferences.categoryOf()` içgörü kimliğinden hangi tercihe ait
olduğunu türetir; yeni içgörü eklendiğinde orayı güncellemek gerekmez.

### Rotalar

Uygulama `MaterialApp.routes` **kullanmıyor** — tüm ekranlar `MainScaffold`
içindeki `IndexedStack`'te. Rota adı `AppRoutes.go()` ile sekmeye çevrilir.

```dart
AppRoutes.go('/accounts');            // ✅ sekme değiştirir
Navigator.pushNamed(ctx, '/accounts') // ❌ kayıtlı rota yok, hata fırlatır
```

Bildirim payload'undaki rota `NotificationService.consumePendingRoute()` ile
okunur ve `main.dart` içinde tüketilir. Uygulama kapalıyken gelen bildirim
`getNotificationAppLaunchDetails` ile yakalanır.

## Durum Bantları

`EmailVerificationBanner` ve `StaleDataBanner` `MainScaffold._contentStack()`
içinde tek yerde durur — her ekranın ayrı ayrı göstermesi gerekmez.
Gösterilecek durum yoksa hiç yer kaplamazlar.

- E-posta doğrulama: kayıtta otomatik gönderilir, band yeniden göndermeyi ve
  durumu tazelemeyi sunar. Google/Apple girişleri doğrulanmış sayılır.
- Bayat veri: piyasa 2 dakikada bir güncelleniyor; `StaleDataBanner.staleAfter`
  (30 dk) aşılırsa band çıkar.

## Kategori Sözleşmesi (ÖNEMLİ)

Firestore'a **her zaman slug yazılır**, asla Türkçe etiket değil:

```dart
category: TransactionCategory.yatirim.slug   // 'yatirim'  ✅
category: 'Yatırım'                           // ❌ net nakit hesabını bozar
```

Okuma tarafı `TransactionCategoryX.parse()` / `.slugOf()` kullanır; bunlar hem
slug'ı hem de eski kayıtlardaki Türkçe etiketleri tanır (migration gerekmez).
`yatirim` kategorisi net nakit ve gider toplamlarından hariç tutulur
(servet transferi, gerçek gider değil).

## Firestore Güvenlik Notu

`users/{uid}` profil belgesinde `role` alanı **istemciden yazılamaz** — yalnızca
`onUserCreated` / Admin SDK yazar. Bu yüzden profil belgesine yazarken
`SetOptions(merge: true)` kullanılmalı; merge'siz `set()` `role` ve `fcmToken`
alanlarını sileceği için güvenlik kuralı isteği reddeder.

## Yayın Hazırlığı

Ayrıntılı kontrol listesi: `docs/yayin-kontrol-listesi.md`
Gizlilik politikası metni: `docs/gizlilik-politikasi.md`

### Platform yapılandırmasında dikkat

**iOS izin metinleri zorunludur.** `NSCameraUsageDescription` ve
`NSPhotoLibraryUsageDescription` olmadan iOS uygulamayı **çökertir** —
kullanıcı reddedemez, sistem doğrudan sonlandırır. OCR ekranı `image_picker`
ve `file_picker` kullandığı için ikisi de gerekli.

**`IPHONEOS_DEPLOYMENT_TARGET` = 15.0.** İki ayrı gerekçe:
`firebase_core 3.x` en az 13.0 istiyor (12.0 ile `pod install` düşer) ve
Apple 2027 baharından itibaren 15.0 altındaki yüklemeleri **kabul etmeyecek**
(uyarı 90068). Cihaz kaybı yok: iOS 15, iOS 13 ile aynı donanımı destekler
(iPhone 6s ve sonrası).

`ios/Flutter/AppFrameworkInfo.plist` içindeki `MinimumOSVersion` **aynı değeri
taşımalı**. Yükleme doğrulaması App.framework'ün bu alanını da okur; 12.0'da
kalırsa proje 15.0 olsa bile 90068 uyarısı sürer.

**Apple ile Giriş zorunlu.** Uygulama Google ile giriş sunduğu için App Store
yönergesi 4.8 gereği Apple ile giriş de sunulmalı.
`Runner.entitlements` içindeki `com.apple.developer.applesignin` eksikse
yükleme reddedilir.

**Android `allowBackup="false"`.** Finansal veri cihaz yedeğine çıkmamalı;
veri zaten Firestore'da kullanıcının hesabında. Android 12+ için ayrıca
`data_extraction_rules.xml` gerekir — `fullBackupContent` tek başına yetmez.

**Google girişi iOS'ta URL şeması ister.** `GoogleService-Info.plist`
içindeki `REVERSED_CLIENT_ID`, `Info.plist` → `CFBundleURLSchemes` altına
yazılmalı. Eksikse kullanıcı tarayıcıdan dönemez, beyaz ekranda kalır.
Bu değer elle senkron tutulmaz: `codemagic.yaml` her derlemede plist'ten
`plutil` ile okuyup `REVERSED_CLIENT_ID_YER_TUTUCU` yer tutucusunun yerine
yazar.

**`aps-environment` = `production`.** TestFlight ve App Store yapıları APNs
üretim ortamını kullanır. `development` bırakılırsa bildirimler **hiç
ulaşmaz** ve sebebi log'a düşmez. Yerelde Xcode ile debug derlemesi
yapılacaksa geçici olarak `development` yapılmalı.

**Yalnızca iPhone.** `TARGETED_DEVICE_FAMILY = 1`. Bu yüzden `Info.plist`
içinde `UISupportedInterfaceOrientations~ipad` **bilerek yok** — bırakılırsa
Apple iPad desteği beyan edildiğini varsayıp iPad ekran görüntüsü ister.

**`NSLocationWhenInUseUsageDescription` kullanılmadığı hâlde var.** Uygulama
konum istemez; anahtar yalnızca Apple'ın yükleme doğrulaması (uyarı 90683)
için duruyor — bağlı SDK'lardan biri konum API'lerine referans veriyor.
Silme, yükleme uyarı verir.

### Hesap silme (App Store 5.1.1(v))

`AccountDeletionService` hem Profil ekranından hem KVKK ekranından çağrılır.
Firestore'da **doküman silmek alt koleksiyonları silmez**, bu yüzden servis
silinecek koleksiyon adlarını elle tutar:

```dart
AccountDeletionService.subcollections   // transactions, assets, goals,
                                        // subscriptions, loans, settings
```

`accounts` listede değildir — altındaki `accountTransactions` önce
temizlenmek zorunda olduğu için ayrıca ele alınır.

**Yeni alt koleksiyon eklendiğinde bu listeye de eklenmeli.** `settings`
(bütçe limitleri) unutulmuştu; kullanıcı "hesabımı sil" dediği hâlde
limitleri sunucuda kalıyordu. `test/account_deletion_test.dart` artık
`lib/` içindeki `users/{uid}/…` zincirlerini tarayıp listeyle karşılaştırır;
listeye eklemeyi unutan bir değişiklik testte düşer.

`user.delete()` **yakın zamanlı giriş** ister. `requires-recent-login`
dönerse şifreyle yeniden doğrulama sunulur; Google/Apple ile girenler
yeniden girişe yönlendirilir.

### Derleme buluttan yapılır

Bu makinede Android SDK ve Xcode yok, `google-services.json` ve
`GoogleService-Info.plist` depoda değil — **yerelde `flutter build`
çalışmaz**. Üç iş akışı `codemagic.yaml` içinde:

| İş akışı | Tetikleyici | Çıktı |
|---|---|---|
| `quality-check` | main'e her push | analyze + test |
| `android-release` | elle | `.aab` → Play **kapalı test** (`alpha`), taslak |
| `ios-release` | elle | `.ipa` → TestFlight |
| `ios-adhoc` | elle | `.ipa` → doğrudan cihaza (TestFlight'ı atlar) |

**iOS imzalama elle yapılandırılmıştır.** Otomatik imzalama
(`distribution_type` + `bundle_identifier`) denendi; Codemagic hesapta
sertifika üretemedi ve her derleme "No matching profiles found" ile durdu.
Sertifika ve profil Apple portalında oluşturulup Codemagic'e yüklendi.
Elle imzalamada `xcode-project use-profiles` adımı **zorunludur** —
`export_options.plist` dosyasını o üretir; adım olmadan IPA derlemesi
"property list does not exist" ile düşer. Pod kurulumundan **sonra**
çalışmalıdır.

**Beta App Review yalnızca DIŞ test kullanıcıları için gerekir.** Liqra'da
yalnızca iç (internal) grup var, bu yüzden `submit_to_testflight: false`.
`true` bırakıldığında Codemagic `betaAppReviewSubmissions` ucuna istek atıyor
ve Apple 422 `BETA_CONTRACT_MISSING` döndürüp derlemeyi kırıyordu — oysa yapı
gruba zaten dağıtılmıştı. Dış grup eklenirse tekrar `true` yapılmalı.

**TestFlight tamamen bloke olabilir — `ios-adhoc` kaçış yoludur.** Apple'ın
arka ucunda uygulamanın Beta Contract kaydı oluşmazsa (`422
BETA_CONTRACT_MISSING`) hem dış grup eklenemez hem de **iç test kullanıcıları
yapıyı indiremez** ("requested app is not available"). Bu yalnızca Apple
mühendisinin elle düzeltebildiği bilinen bir arıza; çözülmesi haftalar
sürüyor. Ad Hoc dağıtım beta sözleşmesine bağlı olmadığı için etkilenmez.
Anlatım: `docs/adhoc-kurulum.md`

**TestFlight'a yükleme, dağıtım demek değildir.** `submit_to_testflight: true`
yapıyı yükler ve "Ready to Test" yapar ama **hiçbir test grubuna atamaz**;
TestFlight uygulamasında hiçbir şey görünmez ve ortada hata da olmaz.
`beta_groups` bu yüzden zorunludur — oradaki ad App Store Connect'teki grup
adıyla birebir aynı olmalı, yoksa yayın adımı durur.

**Android kanalı `alpha` (kapalı test), `internal` DEĞİL.** 13 Kasım 2023
sonrası açılan kişisel Play hesapları üretime çıkmadan önce 12 test
kullanıcısıyla 14 gün kesintisiz **kapalı** test yapmak zorunda; iç test bu
şartı karşılamaz. Uygulamanın Play'e **ilk** yüklemesi API ile yapılamaz —
ilk `.aab` Play Console'a elle yüklenir.

**Android sürüm derlemesi sessizce debug anahtarına düşebilir.**
`build.gradle.kts`, `key.properties` yoksa yalnızca uyarı yazıp debug
anahtarıyla imzalar (yerel geliştirme kesilmesin diye). Codemagic bu dosyayı
`android_signing` tanımından kendisi üretir; üretemezse `.aab` Play'e
yüklenip dakikalar sonra reddedilirdi. `codemagic.yaml` bu yüzden derlemeden
**önce** dosyanın varlığını kontrol edip durur.

### Gizlilik politikası kodla birebir örtüşmeli

Politika bir kez yanlış beyan içeriyordu: "Gemini'ye adınız, IBAN'ınız, kart
numaranız gönderilmez" diyordu — asistan için doğru, ama **belge tarama
görselin/PDF'in kendisini** Gemini'ye gönderiyor ve bir banka ekstresinde bu
bilgilerin hepsi yazılı. Veri akışına dokunan her değişiklikte
`docs/gizlilik-politikasi.md` ve mağaza veri güvenliği beyanı birlikte
güncellenmeli.

### Gizlilik politikası yayında

```
https://emremecf.github.io/liqra/gizlilik-politikasi
```

`docs/` klasörü GitHub Pages ile yayınlanır (`docs/_config.yml`).
`yayin-kontrol-listesi.md` `exclude` listesindedir — dahili not, siteye
çıkmaz. Politika metni değişirse mağaza kayıtlarındaki tarih de
güncellenmeli.

## Açılış Zinciri (ÖNEMLİ)

`main()` içinde **hiçbir yardımcı servis `runApp`'i engelleyemez.**

```dart
await _startOptional('Bildirimler', NotificationService.instance.init);
```

`_startOptional` her servisi kendi `try/catch`'i ve **10 saniyelik zaman
aşımı** ile sarar. Zorunlu olan yalnızca ikisidir: `Firebase.initializeApp`
ve `configureDependencies()`. İkisi de patlarsa `_StartupFailureApp`
gösterilir — sebebi ekranda yazar.

### Neden bu kadar önemli

Eskiden beş servis tek bir `Future.wait` içindeydi. `Future.wait` ilk hatayı
yeniden fırlatır: **herhangi biri** patladığında `main()` çöküyor, `runApp`
hiç çağrılmıyor, ekran siyah kalıyordu. Birkaç saniye sonra iOS watchdog
uygulamayı sonlandırıyordu — dışarıdan "uygulama açılmıyor" ya da "uygulama
yok" gibi görünür ve **hiçbir hata mesajı çıkmaz**.

Bu servislerin hiçbiri açılış için zorunlu değil: Remote Config düşerse
varsayılanlar devreye girer, Analytics düşerse ölçüm kaybolur, bildirim izni
düşerse bildirim gelmez. Uygulama yine çalışır.

Zaman aşımı ayrı bir gerekliliktir: `NotificationService.init()` iOS'ta APNs
jetonu gelmezse **askıda kalabilir**. Sonsuza kadar beklemek de siyah ekran
demektir, çökmekten farkı yoktur.

`NotificationService.init()` beş servis içinde **try/catch'i olmayan tek
servisti**; diğer dördü hatalarını zaten yutuyordu.

### Yeni servis eklerken

Açılışta çağrılan her yeni servis `_startOptional` ile sarılmalı. Zorunlu
olduğunu düşünüyorsan iki kez düşün: kullanıcının uygulamayı hiç açamaması,
o servisin eksik çalışmasından neredeyse her zaman daha kötüdür.

## Tasarım Sistemi (ÖNEMLİ)

Üç dosya tek kaynaktır. **Yeni kodda ham değer yazma** — ölçekten seç.

| Dosya | Ne verir |
|---|---|
| `core/constants/app_colors.dart` | Renk token'ları |
| `core/constants/app_typography.dart` | 16 kademeli tip ölçeği |
| `core/constants/app_dimensions.dart` | `AppRadius`, `AppSpacing`, `AppBorder` |

```dart
color: AppColors.accentRed              // ✅
color: const Color(0xFFFF4757)          // ❌ aynı renk, ikinci kaynak

borderRadius: BorderRadius.circular(AppRadius.md)   // ✅
borderRadius: BorderRadius.circular(15)             // ❌ ölçek dışı

style: AppTypography.bodyM              // ✅
style: GoogleFonts.outfit(fontSize: 14) // ❌ tip ölçeğini atlıyor
```

### Neden bu kadar katı

Denetimde ölçülen tutarsızlık: **143 ham renk**, **18 farklı köşe yarıçapı**,
**27 farklı font boyutu**. Ekranlar tek tek fena değildi ama birbirini
tutmuyordu — yan yana duran iki kartın köşesi ve kenarlığı farklıydı. Göz
bunu "bozuk" diye okur, nedenini söyleyemez.

Aynı rengin iki kopyası dolaşıyordu: `#FF4757` ve `#FF6B7A` (kırmızı),
`#E4B84A` ve `#D4A017` (altın). Tek renge indirildi.

Marka paleti **teal + gold**. Asistanın moru (`accentPurple`) ve bilgi mavisi
(`accentBlue`) token olarak tanımlıdır; bunların dışına çıkma.

Banka marka renkleri (`BankNameExt.primaryColor`), grafik paleti
(`AppColors.chartColors`) ve Google giriş düğmesi (`googleBlue`) bilinçli
istisnalardır — token'a çekilmezler.

### Alt navigasyon

Nav çubuğu `presentation/widgets/liqra_bottom_nav.dart` içinde ayrı bir
bileşendir — `MainScaffold` içinde özel metot olduğu sürece tasarım
önizlemesinde gösterilemiyordu.

İki ölçü kuralı birlikte çalışır; biri bozulursa çentik kırılır:

```dart
LiqraBottomNav.fabSize      // 58 — FAB çapı
LiqraBottomNav.notchMargin  // 10 — BottomAppBar.notchMargin ile AYNI
LiqraBottomNav.notchWidth   // 78 — sekmeler arası boşluk bundan küçük olamaz
```

- **Çocuk widget arka plan boyamamalı.** `BottomAppBar` çentikli şekli kendi
  çizer; içine `color`/`gradient` taşıyan bir `Container` konursa düz
  dikdörtgen üste boyanır ve **çentik hiç görünmez** — FAB çubuğun üstüne
  yapıştırılmış gibi durur. Üst kenarlık yerine `elevation` kullanılır;
  `Border(top:)` çentiğin etrafını dolanamaz.
- **Sekmeler `Expanded`.** Sabit genişlikteyken 4×72 + 68 = 356 piksel
  gerekiyordu; 360 piksellik ekranda 4 piksel kalıyor, 320 pikselde
  taşıyordu.

### Tasarım önizleme

Uygulama `google-services.json` olmadan derlenmiyor, bu yüzden bileşenleri
görmek için Firebase'e hiç dokunmayan ayrı bir giriş var:

```bash
flutter run -d chrome -t lib/design_preview.dart
```

Bileşenler sahte veriyle yan yana dizilir; tutarsızlık saniyeler içinde
görünür. Yeni bir paylaşılan bileşen eklerken galeriye de ekle.

## Localization & Formatting

`formatters.dart` ile Türkçe para birimi (`289.847,50 TL`), yüzde (`+12,4%`), kompakt (`289,8B`).  
`DateFormat(..., 'tr_TR')` **kullanma** — `initializeDateFormatting('tr_TR')`
çağrılmadığı için `LocaleDataException` atar. Bunun yerine `Formatters.date` /
`Formatters.shortDate` / `Formatters.monthYear` kullan (manuel ay isimleri,
bağımlılık yok). `NumberFormat.currency(locale: 'tr_TR', ...)` güvenlidir —
sayı sembolleri intl paketiyle birlikte gelir.

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
