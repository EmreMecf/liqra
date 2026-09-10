# Liqra — Ad Hoc ile Telefona Kurulum (TestFlight'sız)

TestFlight, Apple'ın arka ucundaki `BETA_CONTRACT_MISSING` arızası yüzünden
çalışmıyor. Ad Hoc dağıtımın beta sözleşmesiyle **hiçbir ilgisi yoktur**, bu
yüzden arızadan etkilenmez ve uygulamayı hemen test edebilirsin.

**Mac gerekmiyor.** Her şey Windows + Codemagic ile yapılır.

Sınır: cihaz UDID'si profile gömülür, yalnızca kayıtlı cihazlara kurulur
(üyelik yılı başına en fazla 100 iPhone).

---

## 1. iPhone'un UDID'sini al

UDID, telefonun 25 veya 40 karakterlik benzersiz kimliğidir. Ayarlar'da
görünmez.

**Windows'ta en güvenli yol — Apple Devices uygulaması:**

1. Microsoft Store'dan **Apple Devices** uygulamasını kur
   (iTunes'un yerini alan resmî Apple uygulaması)
2. iPhone'u kabloyla bağla, telefonda **Bu Bilgisayara Güven** de
3. Sol taraftan cihazı seç
4. Cihaz adının altındaki bilgi satırına **tıkla** — her tıklamada değişir:
   seri numarası → UDID → ECID
5. UDID görününce **sağ tık → Kopyala**

> UDID gösterdiğini iddia eden rastgele web sitelerine profil yükleme.
> O siteler cihazına yapılandırma profili kurar ve kimliğini toplar.
> Apple'ın kendi uygulaması varken buna gerek yok.

---

## 2. Cihazı Apple portalına kaydet

> developer.apple.com/account → **Devices** → mavi **+**

| Alan | Değer |
|---|---|
| Platform | iOS |
| Device Name | `Emre iPhone 15` (serbest) |
| Device ID (UDID) | 1. adımda kopyaladığın değer |

**Continue → Register.**

---

## 3. Ad Hoc provisioning profile üret

> developer.apple.com/account → **Certificates, Identifiers & Profiles**
> → **Profiles** → mavi **+**

Sırayla:

1. **Distribution** başlığı altından **Ad Hoc** seç → Continue
   (Development değil, App Store değil — **Ad Hoc**)
2. App ID: **com.emrec.muhasebe** → Continue
3. Sertifika: TestFlight için oluşturduğun **dağıtım sertifikasını** seç
   → Continue
4. Cihazlar: 2. adımda kaydettiğin iPhone'u **işaretle** → Continue
5. Provisioning Profile Name: `Liqra Ad Hoc` → **Generate**
6. **Download** — `.mobileprovision` dosyası iner

⚠️ Yeni bir cihaz eklediğinde bu profili **yeniden üretmen** gerekir.
Profil, üretildiği andaki cihaz listesini içinde taşır.

---

## 4. Profili Codemagic'e yükle

> Codemagic → App settings → **Code signing identities**
> → **iOS provisioning profiles** → Upload profile

- İndirdiğin `.mobileprovision` dosyasını seç
- **Reference name:** `liqra_adhoc`

Bu ad `codemagic.yaml` içindeki `provisioning_profiles` değeriyle **birebir
aynı olmalı**, yoksa derleme imzalama adımında durur.

Sertifika zaten yüklü (`liqra_distribution`) — tekrar yüklemene gerek yok.

---

## 5. Derlemeyi çalıştır

> Codemagic → **Start new build** → Workflow: **Liqra · iOS (Ad Hoc)**

Bittiğinde **Artifacts** bölümünden `.ipa` dosyasını indir.
(E-posta bildirimi de gelir.)

---

## 6. Telefona kur

IPA'yı bir linke tıklayarak kuramazsın — iOS, `itms-services` biçiminde bir
manifest ister. Bunu senin için üreten bir servis gerekiyor.

### Seçenek A — Firebase App Distribution (önerilen)

Zaten Firebase kullanıyorsun; ekstra bir şirkete uygulama dosyanı vermezsin.

1. Firebase Console → **App Distribution** → başlat
2. iOS uygulamasını seç (`com.emrec.muhasebe`)
3. `.ipa` dosyasını sürükle-bırak
4. Test kullanıcısı olarak kendi e-postanı ekle
5. Telefona gelen davetten **App Tester** uygulamasını kur, oradan yükle

### Seçenek B — Diawi (en hızlı, tek seferlik)

1. diawi.com adresine `.ipa` dosyasını yükle
2. Çıkan linki iPhone'da **Safari** ile aç (Chrome değil)
3. **Yükle** de

Uygulama dosyan üçüncü bir servise çıkar. Tek cihazda hızlı deneme için
uygun; alışkanlık hâline getirme.

---

## Kurulum sonrası

İlk açılışta iOS "Güvenilmeyen Geliştirici" diyebilir:

> Ayarlar → Genel → **VPN ve Aygıt Yönetimi** → geliştiriciye **Güven**

Ad Hoc yapılar **1 yıl** geçerlidir (TestFlight'ta 90 gün). Sertifika
yenilenirse yeniden imzalanması gerekir.

---

## TestFlight düzelince

Apple beta contract kaydını oluşturunca bu yola gerek kalmaz:

- `codemagic.yaml` → `ios-release` iş akışını kullan
- Dış test grubu ekleyeceksen `submit_to_testflight` değerini `true` yap

`ios-adhoc` iş akışını silme — yeni bir cihazda hızlı deneme yapmak ya da
TestFlight yine tökezlerse geri dönmek için elinde dursun.
