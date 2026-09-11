# Liqra — Canlıya Çıkış Yol Haritası

Son denetim: 11 Eylül 2026 · `flutter analyze` temiz · 166 test geçiyor ·
Ad Hoc yapı gerçek iPhone'da çalıştı

Bu dosya `docs/_config.yml` içinde `exclude` listesindedir — GitHub Pages'te
yayınlanmaz, depoda kalır. Mağaza metinleri: `docs/magaza-metinleri.md`

---

## Kritik yol — neden bu sıra

**Android en uzun kalem.** Kişisel Play hesapları üretime çıkmadan önce
**12 test kullanıcısıyla 14 gün kesintisiz** kapalı test yapmak zorunda,
ardından üretim erişimi başvurusu ~7 gün sürüyor. Yani Android'de en erken
yayın, testin başladığı günden **~3 hafta** sonra. Bu yüzden **ilk gün**
başlatılmalı; iOS işleri o 14 gün içinde yapılır.

**iOS incelemesi** genelde 24-48 saat sürer.

| Gün | Android | iOS | Ortak |
|---|---|---|---|
| 1 | Keystore, Play'de uygulama, ilk .aab elle yükle, kapalı test başlasın | — | Push, Functions deploy, Gemini faturalandırma + anahtar |
| 2-3 | 12 test kullanıcısı katılsın | Yeni derleme, mağaza sayfası, gizlilik etiketleri | İnceleme hesabı |
| 3-4 | (test sürüyor) | **İncelemeye gönder** | — |
| 5-6 | (test sürüyor) | Onay → **iOS yayında** | — |
| 15 | Üretim erişimi başvurusu | — | — |
| ~22 | Onay → **Android yayında** | — | — |

---

## Aşama 0 — Ortak (her iki platformdan önce)

### 0.1 Push

Yerel commit'ler GitHub Desktop → **Push origin** ile gönderilir. Codemagic
derlemeyi GitHub'daki koddan alır; push edilmeyen düzeltme mağazaya gitmez.

### 0.2 Cloud Functions ve Firestore kuralları

Düzeltilen RSS kaynakları, kampanya temizliği ve ASCII slug'lar **hâlâ yayında
değil**. Canlıya çıkan kullanıcı eski (üçü ölü) haber kaynaklarını görür.

Node.js kurulu bir bilgisayarda:

```powershell
npm install -g firebase-tools
firebase login
firebase deploy --only functions,firestore:rules
```

CollectAPI anahtarı Secret Manager'da tanımlı olmalı:

```powershell
firebase functions:secrets:set COLLECT_API_KEY
```

Blaze planı gerekli — ücretsiz plan Cloud Functions'tan dışarı ağ isteğine
izin vermiyor.

### 0.3 Gemini: ücretli katman ZORUNLU, anahtarı kısıtla, bütçe alarmı kur

**Önce faturalandırma — bu bir yayın engeli.** Gemini API'nin ücretsiz
katmanında Google gönderilen içeriği kendi ürünlerini geliştirmek için
kullanıyor, **insan incelemeciler okuyabiliyor** ve şartlar açıkça "ücretsiz
hizmete hassas, gizli veya kişisel bilgi göndermeyin" diyor. Liqra finansal
özet ve banka ekstresi PDF'i gönderiyor. Ayrıca AB/İngiltere/İsviçre'deki
kullanıcılara açılan uygulamalarda ücretli katman şart.

Gizlilik politikası "ücretli API hizmeti kapsamında kullanılır" diyor — bu
ancak faturalandırma açıksa doğru.

1. aistudio.google.com → **API keys** → anahtarın bağlı olduğu **Cloud
   projesini** gör
2. O projede **aktif bir faturalandırma hesabı** olmalı (AI Studio'da anahtarın
   yanında "Paid" / "Tier 1" görünür). Anahtar Blaze planlı `finansasistaniapp`
   projesindeyse zaten ücretli; ayrı bir varsayılan projedeyse faturalandırma
   bağla ya da anahtarı `finansasistaniapp` projesinde yeniden oluşturup
   Remote Config'deki `gemini_api_key` değerini güncelle

Gemini Flash ucuz; küçük bir kullanıcı tabanında aylık maliyet birkaç dolar
düzeyinde kalır.

**Sonra kısıtlama.** Anahtar Remote Config ile **uygulamanın içine**
iniyor. Uygulama paketini açan herkes onu çıkarıp senin faturana istek atabilir; uygulamadaki saatlik
20 istek sınırı yalnızca istemcide, anahtarı çalan onu atlar.

Yayından önce en azından:

1. Google Cloud Console → **APIs & Services → Credentials** → Gemini anahtarı
   → **API restrictions** → yalnızca **Generative Language API**
2. **Billing → Budgets & alerts** → aylık bütçe (ör. 20 $) ve %50 / %90 / %100
   e-posta alarmı

Kalıcı çözüm (yayın sonrası): Gemini çağrılarını Firebase AI Logic üzerinden
yapıp **App Check** ile korumak — anahtar hiç istemciye inmez.

### 0.4 İnceleme için ayrı bir test hesabı

Apple incelemesi giriş gerektiren uygulamalarda **çalışan bir hesap** ister;
Play'in üretim erişimi başvurusu da uygulamanın nasıl test edildiğini sorar.

- Uygulamadan **yalnızca inceleme için** yeni bir e-posta hesabı aç
  (kişisel hesabını verme)
- İçine gerçekçi örnek veri gir: 1 banka hesabı, 1 kredi kartı, 10-15 işlem,
  1 bütçe limiti, 2-3 portföy varlığı, 1 hedef. Boş hesapla gönderilen
  finans uygulaması "ne yaptığını göremedik" gerekçesiyle reddedilir
- ⚠️ TestFlight **Test Information** sayfasındaki mevcut şifre ekran
  görüntüsüyle paylaşıldı — o hesabı kullanacaksan şifresini değiştir

---

## Aşama 1 — Android (kritik yol, hemen başla)

### 1.1 Hesap türünü kontrol et

Play Console → **Hesap ayrıntıları**. Hesap **kişisel** ve **13 Kasım 2023'ten
sonra** açıldıysa (kapatılıp yeniden açılan hesap da buna girer) 12 kişi /
14 gün şartı geçerli. Kuruluş hesabıysa bu şart yok, doğrudan üretime
çıkabilirsin.

### 1.2 İmzalama anahtarı

```powershell
keytool -genkey -v -keystore liqra-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias liqra
```

Codemagic → Code signing identities → **Android keystores** → yükle,
referans adı: **`liqra_keystore`**

Yeni uygulamalarda **Play App Signing** zorunlu: uygulamayı asıl imzalayan
anahtarı Google tutar, senin anahtarın yalnızca "yükleme anahtarı"dır.
Kaybedersen Play Console → Play app signing → **Request upload key reset** ile
1-2 iş gününde yenisini alabilirsin. Yine de yedeğini şifreli bir yerde tut.

### 1.3 Play Console'da uygulamayı oluştur

Uygulama oluştur → ad **Liqra** · varsayılan dil **Türkçe** · **Uygulama** ·
**Ücretsiz**.

Sonra servis hesabı (Codemagic otomatik yükleme için):
Play Console → **Kurulum → API erişimi** → servis hesabı oluştur → JSON'u
Codemagic `google_play` grubuna `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` olarak
ekle.

### 1.4 İlk .aab — ELLE yükle

Uygulamanın Play'e **ilk** yüklemesi API ile yapılamaz.

1. Codemagic → **Liqra · Android** çalıştır
2. Artifacts'ten `.aab` dosyasını indir
3. Play Console → **Test → Kapalı test** → yeni sürüm → `.aab` yükle →
   sürüm notu → yayınla

Sonraki sürümler `codemagic.yaml` üzerinden otomatik olarak **kapalı test**
kanalına (`alpha`) gider. İç test (`internal`) 14 günlük şartı
karşılamadığı için bilerek kullanılmıyor.

### 1.5 12 test kullanıcısı, 14 gün

- Kapalı teste en az **12** Google hesabı ekle (e-posta listesi)
- Her biri davet linkinden **katılmalı VE uygulamayı kurmalı** — davet edilip
  kurmayan sayılmaz
- **14 gün kesintisiz** katılımda kalmalılar; biri çıkarsa sayaç etkilenir
- Güvenli olmak için **15-20 kişi** ekle
- Test süresince 1-2 güncelleme yayınla ve testçilerden geri bildirim al —
  üretim başvurusunda "testte ne öğrendin, ne değiştirdin" diye soruluyor

### 1.6 Uygulama içeriği formları

Play Console → **Politika ve programlar → Uygulama içeriği**. Hepsi
doldurulmadan yayın yapılamaz:

| Form | Liqra için |
|---|---|
| Gizlilik politikası | `https://emremecf.github.io/liqra/gizlilik-politikasi` |
| Reklamlar | Reklam **yok** |
| Uygulama erişimi | Giriş gerekiyor → inceleme hesabı bilgileri (0.4) |
| İçerik derecelendirmesi | Anketi doldur — şiddet/kumar vb. yok |
| Hedef kitle | **18+** (gizlilik politikası 18 yaş altını hariç tutuyor) |
| Veri güvenliği | Aşağıdaki "Hazır bilgi" bölümü |
| **Finansal özellikler beyanı** | Zorunlu — aşağıya bak |
| Hükümet uygulaması | Hayır |

**Finansal özellikler beyanı:** Doğru beyan et. Liqra kişisel bütçe/harcama
takibi yapar ve **bilgilendirme amaçlı** piyasa analizi sunar. Kredi,
ödeme, para transferi, alım-satım aracılığı, kripto cüzdanı **yoktur**.
Bankaya bağlanmaz; tüm veriyi kullanıcı elle girer.

### 1.7 Mağaza kaydı

Metinler: `docs/magaza-metinleri.md`

| Öğe | Ölçü |
|---|---|
| Uygulama ikonu | 512×512 PNG |
| Öne çıkan grafik | 1024×500 |
| Telefon ekran görüntüsü | En az 2, en fazla 8 (9:16, en az 1080 px kısa kenar) |
| Kısa açıklama | 80 karakter |
| Tam açıklama | 4000 karakter |
| Kategori | Finans |
| İletişim e-postası | Zorunlu |

### 1.8 Üretim erişimi başvurusu

14 gün dolunca Play Console → **Kontrol paneli → Üretim erişimi başvurusu**.
Üç bölüm: kapalı test nasıl geçti, uygulama hakkında, üretime hazırlık.
Google'ın incelemesi genelde **7 gün veya daha kısa**.

Onaydan sonra `codemagic.yaml` içinde `track: production` yap ya da sürümü
Play Console'dan kapalı testten üretime **terfi ettir**. İlk yayında
**kademeli dağıtım** (%20 → %50 → %100) öner.

---

## Aşama 2 — iOS

### 2.1 Yeni derleme

TestFlight'taki **build 5 eski**: Apple ile Giriş'in yerel akışı, Google
girişindeki çökme düzeltmesi, Gemini hata mesajları, ana sayfa sadeleştirmesi
ve yatırım uyarısı onda **yok**. İncelemeye onu gönderme.

Codemagic → **Liqra · iOS (App Store)** çalıştır. Yapı App Store Connect'e
yüklenir (`submit_to_testflight: false` — beta incelemesi yok).

### 2.2 App Store sayfası

App Store Connect → Liqra → **1.1.0 Hazırlanıyor**:

| Alan | Değer |
|---|---|
| Ekran görüntüleri | Yalnızca **6.9" iPhone** yeter: 1320×2868 (ya da 1290×2796). En az 1, en fazla 10. Küçük ekranlara Apple ölçekler |
| Tanıtım metni | 170 karakter |
| Açıklama | 4000 karakter |
| Anahtar kelimeler | 100 karakter, virgülle |
| Destek URL'si | `https://emremecf.github.io/liqra/` |
| Pazarlama URL'si | (isteğe bağlı) aynı adres |
| Telif hakkı | `2026 Emre Çiftci` |

iPad ekran görüntüsü **gerekmiyor** — uygulama iPhone-only.

### 2.3 Uygulama Bilgileri

- Alt başlık (30 karakter), kategori **Finans**, ikincil kategori (isteğe bağlı)
- **Yaş derecelendirmesi** anketi
- **Gizlilik politikası URL'si**: `https://emremecf.github.io/liqra/gizlilik-politikasi`
- **Uygulama Gizliliği** (gizlilik etiketleri) — aşağıdaki "Hazır bilgi"

### 2.4 Fiyat ve bulunabilirlik

Ücretsiz · ülkeler: en azından Türkiye (tümü seçilebilir; uygulama Türkçe).

### 2.5 App Review Information

- **Sign-in required** işaretli → 0.4'teki inceleme hesabı
- İletişim bilgileri
- **Notes** alanına `docs/magaza-metinleri.md` içindeki inceleme notunu
  yapıştır. Bankaya bağlanmadığını, AI analizinin bilgilendirme amaçlı
  olduğunu ve kampanyaların örnek içerik olduğunu önceden söylemek, "bu
  uygulama gerçekten ne yapıyor" sorusuyla gelen retlerin önünü keser

### 2.6 Gönder

Build bölümünden **yeni derlemeyi** seç → **İncelemeye Ekle** → **Gönder**.

**Yayın zamanı** için "Manually release" seç: onay gelince sen basarsın,
gece yarısı habersiz yayına çıkmaz. İlk sürümde **Phased Release** (7 günde
kademeli) açılabilir.

### 2.7 TestFlight arızası mağazayı etkiler mi

`BETA_CONTRACT_MISSING` TestFlight'ın beta sözleşmesiyle ilgili. Forum
raporlarında **üretim yüklemelerinin normal çalıştığı** belirtiliyor ama
"İncelemeye Ekle" adımının etkilenmediği açıkça doğrulanmış değil. Gönderim bu
hatayla takılırsa Apple destek talebine bunu da ekle.

Apple'a açılan destek kaydını kapatma — TestFlight ileride dış test için
lazım olacak.

---

## Aşama 3 — Yayın günü ve sonrası

- **Crashlytics**'i ilk 48 saat sık kontrol et — gerçek cihaz çeşitliliği
  Ad Hoc'ta görmediğin çökmeleri çıkarır
- **Firebase kullanım/fatura** panelini ilk hafta takip et
- Gelen yorumlara yanıt ver; ilk 1-2 haftadaki puan mağaza sıralamasını
  belirler
- Hata düzeltme sürümünde pubspec'te **sürüm adını** artır (`1.1.1`); build
  numarasını CI kendisi artırıyor

---

## ✅ Tamamlananlar

| Konu | Durum |
|---|---|
| iOS Firebase yapılandırması | `firebase_options.dart` iOS bloğu · `firebase.json` iOS platformunu tanıyor |
| iOS izin metinleri | Kamera, galeri, galeriye kaydetme, Face ID, konum (uyarı 90683) |
| iOS dağıtım hedefi | 15.0 (3 yapılandırma) + `AppFrameworkInfo.plist` — uyarı 90068 kapandı |
| iOS yetkiler | `aps-environment: production` · Apple ile Giriş |
| Apple ile Giriş | Tarayıcı yerine iOS yerel akışı |
| Google ile Giriş | Butona basınca çökme giderildi (`GIDClientID` Info.plist'e yazılıyor) |
| Cihaz ailesi | Yalnızca iPhone |
| Android hedef API | 36 (Play'in 31 Ağustos 2026 şartı) |
| Android yedekleme | `allowBackup=false` + veri çıkarma kuralları |
| Android imzalama | `key.properties` okunuyor; anahtar yoksa Codemagic derlemeden önce duruyor |
| Android kanal | Kapalı test (`alpha`) — 14 gün şartını karşılayan kanal |
| Hesap silme | Tüm alt koleksiyonlar dâhil (App Store 5.1.1(v)) |
| Veri dışa aktarma | KVKK ekranında CSV |
| Açılış dayanıklılığı | Yardımcı servis patlarsa uygulama yine açılıyor |
| Yatırım uyarısı | Hisse analizi ve asistan ekranında görünür; prompt al/sat talimatını yasaklıyor |
| Gizlilik politikası | **Yayında** → https://emremecf.github.io/liqra/gizlilik-politikasi |
| Gerçek cihaz testi | Ad Hoc yapı iPhone 15'te çalıştı |
| Gizlilik politikası doğruluğu | Belge taramanın görseli/PDF'i Gemini'ye gönderdiği yazıldı (eskiden "IBAN gönderilmez" diyordu — ekstre PDF'inde IBAN yazılı) · isteğe bağlı IBAN alanı eklendi |

---

## 📋 Mağaza formları için hazır bilgi

### Uygulama kimliği
- **Paket adı / Bundle ID:** `com.emrec.muhasebe`
- **Sürüm:** 1.1.0 (build numarasını CI otomatik artırır)
- **Kategori:** Finans
- **Minimum sürüm:** Android 6.0 (API 23) · iOS 15.0
- **Cihaz:** yalnızca iPhone (iPad desteklenmiyor)
- **Hedef yaş:** 18+

### İzinler ve gerekçeleri

| İzin | Neden |
|---|---|
| `CAMERA` | Fiş/fatura tarama (OCR) |
| `POST_NOTIFICATIONS` | Ekstre ve bütçe hatırlatmaları |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Firestore ve piyasa verisi |
| `NSLocationWhenInUse` (iOS) | **Kullanılmıyor** — bağımlı bir SDK'nın referansı yüzünden amaç metni tanımlı |

### Veri Güvenliği / Gizlilik etiketleri

Toplanan veri türleri:

- **Kişisel bilgi:** e-posta, ad (kimlik doğrulama)
- **Finansal bilgi:** kullanıcının elle girdiği işlem, bakiye, borç, portföy
- **Fotoğraflar ve dosyalar:** fiş, fatura, banka ekstresi — metne
  dönüştürülmek üzere Google Gemini'ye gönderilir, Liqra'da saklanmaz.
  Belgede basılı ad, IBAN ve kart haneleri de gönderime dahil
- **Uygulama etkinliği:** çökme raporu, ekran görüntüleme (Analytics)
- **Cihaz kimliği:** FCM bildirim token'ı

Beyan edilecekler:

- Veri **şifreli** aktarılıyor (HTTPS) — ✅
- Kullanıcı **silme** talep edebiliyor — ✅ Profil → Hesabı Sil
- Veri **satılmıyor / reklamla paylaşılmıyor** — ✅
- **İzleme (tracking) için kullanılmıyor** — ✅
- Veri kullanıcıya **bağlı** — ✅
- **Google Gemini** hizmet sağlayıcı olarak veri alıyor: asistan kullanılırsa
  finansal özet (kimlik bilgisi hariç), belge taranırsa görselin/PDF'in
  kendisi. Gizlilik politikası 3. bölümde ikisi de yazıyor. Play'in
  tanımında sizin adınıza işleyen hizmet sağlayıcıya aktarım "paylaşım"
  sayılmaz ama veri "toplanan" olarak beyan edilir

⚠️ **Banka bağlantısı olmadığını açıkça belirt.** Finans kategorisinde "banka
verisi" beyanı ek doğrulama süreci başlatır; Liqra'da bankaya bağlanma yok,
tüm veriyi kullanıcı elle giriyor.

---

## 🚀 Derleme iş akışları

Yerelde derleme **yapılmıyor**: bu makinede Android SDK ve Xcode yok, Firebase
yapılandırma dosyaları depoda değil. Her şey Codemagic üzerinden çıkıyor.

| İş akışı | Ne yapar | Nereye gider |
|---|---|---|
| `quality-check` | Her push'ta analyze + test | — |
| `android-release` | `.aab` | Play → **kapalı test** (`alpha`), taslak |
| `ios-release` | `.ipa` | App Store Connect (TestFlight listesi) |
| `ios-adhoc` | `.ipa` | Kayıtlı cihaza doğrudan — bkz. `docs/adhoc-kurulum.md` |

Hiçbiri doğrudan üretime göndermiyor. Mağaza incelemesine ve Play üretim
kanalına geçiş elle yapılır.

---

## ⚠️ Bilinen sorunlar

**TestFlight — `422 BETA_CONTRACT_MISSING`.** Apple'ın arka ucunda
uygulamanın beta sözleşmesi kaydı oluşmamış; dış test grubu eklenemiyor ve iç
test kullanıcıları yapıyı indiremiyor. Yalnızca Apple mühendisi düzeltebiliyor
(forum raporlarında 1-3 hafta). Geliştirici tarafında yapılacak bir şey yok:
sözleşmeler, vergi formları ve banka bilgisi tam. Destek kaydı açık tutulmalı.
Bu arada gerçek cihaz testi `ios-adhoc` ile yapılıyor.

---

## ⏳ Yayına engel olmayanlar

| İş | Not |
|---|---|
| Gemini anahtarı istemcide | 0.3'teki kısıtlama geçici önlem; kalıcısı Firebase AI Logic + App Check |
| Erişilebilirlik | Kod tabanında hiç `Semantics` etiketi yok; ekran okuyucu deneyimi zayıf |
| Kampanya verisi | Tamamı örnek (`isSample: true`); canlı banka kaynağı bağlı değil |
| Fon fiyatları | TEFAS fiyat ucu kapalı; kullanıcı elle giriyor |
| CollectAPI kullanımı | `fetchMarketData` 7/24 2 dakikada bir çalışıyor; borsa saati kontrolü yok — maliyetin ~%60'ı boşa |
