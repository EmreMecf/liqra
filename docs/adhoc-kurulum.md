# Liqra — Ad Hoc ile Telefona Kurulum (TestFlight'sız)

TestFlight, Apple'ın arka ucundaki `BETA_CONTRACT_MISSING` arızası yüzünden
çalışmıyor. Ad Hoc dağıtımın beta sözleşmesiyle **hiçbir ilgisi yoktur**, bu
yüzden arızadan etkilenmez ve uygulamayı hemen test edebilirsin.

**Mac gerekmiyor.** Her şey Windows + Codemagic ile yapılır.

Sınır: cihaz UDID'si profile gömülür, yalnızca kayıtlı cihazlara kurulur
(üyelik yılı başına en fazla 100 iPhone).

---

## 1. iPhone'un UDID'sini al

UDID, telefonun benzersiz kimliğidir. Ayarlar'da görünmez.

2018 sonrası cihazlarda (iPhone 15 dâhil) biçim şudur — 8 hane, tire,
16 hane:

```
00008120-001A2B3C0123456E
```

Bunu seri numarasıyla karıştırma: seri numarası 10-12 karakterdir, UDID
25 karakter. Uzunluğa bakarak doğru olanı ayırt edebilirsin.

### Yöntem A — Aygıt Yöneticisi (Apple yazılımı GEREKMEZ)

İş bilgisayarında yönetici yetkisi yoksa ya da Apple Devices kurulamıyorsa
bu yol çalışır. Windows'un telefonu USB'de görmesi yeterli.

1. iPhone'u kabloyla bağla, telefonun kilidini aç, **Güven** de
2. Windows tuşu + R → `devmgmt.msc`
3. Şu iki yerden birinde telefonu bul:
   - **Taşınabilir Aygıtlar** → `Apple iPhone`
   - **Evrensel Seri Veri Yolu aygıtları** → `Apple Mobile Device USB Device`
4. Çift tıkla → **Ayrıntılar** sekmesi
5. Özellik listesinden **Aygıt örneği yolu**nu seç
6. Değer şuna benzer (ters bölü işaretleriyle ayrılmış üç parça):

   `USB` → `VID_05AC&PID_12A8` → `00008120001A2B3C0123456E`

7. **Son parçayı** al ve **8. haneden sonra tire koy**:

   ```
   00008120-001A2B3C0123456E
   ```

Son parça 10-12 karakterlik kısa bir metinse o seri numarasıdır, UDID
değil — diğer konuma bak.

### Yöntem B — Apple Devices uygulaması

1. Microsoft Store'dan **Apple Devices** uygulamasını kur (iTunes'un yerini
   alan resmî Apple uygulaması)
2. iPhone'u bağla, telefonda **Bu Bilgisayara Güven** de
3. Soldan cihazı seç
4. Cihaz adının altındaki bilgi satırına **tıkla** — her tıklamada değişir:
   seri numarası → UDID → ECID
5. UDID görününce **sağ tık → Kopyala**

Sürücü kurduğu için yönetici yetkisi ister.

### Yöntem C — Mac'i olan biri

Finder → kenar çubuğundan iPhone → cihaz adının altındaki bilgi satırına
tıkla → UDID görünür → sağ tık → Kopyala.

### Yöntem D — Üçüncü taraf UDID siteleri

Bilgisayarın hiç yoksa kalan tek yol. **Ne olduğunu bilerek yap:**

Bu siteler telefonuna bir **yapılandırma profili** kurar; profil UDID'ni,
seri numaranı, IMEI'ni ve model bilgini o siteye gönderir. Site bu verileri
saklar. Yaptığı iş budur — kaçınılmaz, sitenin kötü niyetli olması gerekmez.

Kullanacaksan:

1. Bilinen bir site seç, reklam yığını olan rastgele siteleri kullanma
2. Profili yükle, UDID'yi **hemen kopyala**
3. **Profili derhâl sil:**
   > Ayarlar → Genel → **VPN ve Aygıt Yönetimi** → profili seç → **Sil**

Profili silmeyi unutma; kalırsa cihazın o siteye bağlı kalmaya devam eder.

### Sonraki cihazlar için kabloya gerek yok

İlk cihazı kaydedip Ad Hoc yapıyı bir kez ürettikten sonra, yeni test
cihazlarının UDID'sini **Firebase App Distribution kendisi topluyor**: test
kullanıcısı yapıyı indirmeye çalışınca "cihazını kaydet" diyor ve UDID'yi
sana e-postayla gönderiyor. Sen portala ekleyip profili yenilersin.

Bu kablo işini yalnızca **bir kez** yapacaksın.

---

## Telefon bilgisayarda hiç görünmüyorsa

Sırayla dene; çoğu ilk iki maddede çözülür.

| Sorun | Ne yap |
|---|---|
| Kablo sadece şarj kablosu | iPhone 15 USB-C. Piyasadaki C kabloların çoğu veri taşımaz. Apple'ın kendi kablosunu kullan. Şarj olması "bağlandı" demek değil. |
| Telefon kilitli | "Bu Bilgisayara Güven" uyarısı yalnızca telefon **açıkken** çıkar. Kabloyu çıkar, telefonu aç, tekrar tak. |
| Güven uyarısı hiç çıkmıyor | Daha önce "Güvenme" denmiş olabilir, karar hatırlanıyor: Ayarlar → Genel → iPhone'u Aktar veya Sıfırla → Sıfırla → **Konumu ve Gizliliği Sıfırla**. Veriye dokunmaz. |
| Sürücü yok | Aygıt Yöneticisi'nde sarı ünlem varsa: sağ tık → Sürücüyü güncelleştir → Bilgisayarıma gözat → `C:\Program Files\Common Files\Apple\Mobile Device Support\Drivers` |
| Servis durmuş | Windows + R → `services.msc` → **Apple Mobile Device Service** → Yeniden Başlat |
| Port sorunu | Kasanın **arkasındaki** portu dene; ön panel ve USB hub'lar sık sorun çıkarır |

**İş bilgisayarıysa:** sürücü kurmak ve servis başlatmak yönetici yetkisi
ister; bazı kurumlar USB aygıtlarını grup ilkesiyle tamamen kapatır. Aygıt
Yöneticisi'nde telefon hiç görünmüyorsa ve kablodan eminsen sebep budur —
evdeki bilgisayardan yap. UDID'yi bir kez alman yeterli.

---

## 2. Cihazı Apple portalına kaydet

> developer.apple.com/account → **Devices** → mavi **+**

| Alan | Değer |
|---|---|
| Platform | iOS |
| Device Name | `Emre iPhone 15` (serbest) |
| Device ID (UDID) | 1. adımda aldığın değer |

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
- **Reference name:** `liqra_ad_hoc`

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
