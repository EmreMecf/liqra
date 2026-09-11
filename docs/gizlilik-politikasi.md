---
title: Liqra — Gizlilik Politikası
description: Liqra mobil uygulamasının kişisel veri işleme esasları ve KVKK aydınlatma metni.
---

# Liqra — Gizlilik Politikası

**Son güncelleme:** 11 Eylül 2026
**Veri sorumlusu:** Emre Çiftci
**İletişim:** emreciftci873@gmail.com

> Bu metin hem Google Play hem App Store'un zorunlu tuttuğu gizlilik
> politikasıdır. Yayına çıkmadan önce **herkese açık bir URL'de** yayınlanmalı
> ve o URL mağaza kayıtlarına girilmelidir. Bir avukat gözden geçirmeden nihai
> kabul edilmemelidir — burada yazanlar uygulamanın kodda yaptığı işi
> tarif eder, hukuki yeterlilik iddiası taşımaz.

---

## 1. Hangi verileri işliyoruz

Liqra kişisel finans takibi yapar. İşlediğimiz veriler:

### Hesap bilgileri
- E-posta adresi ve şifre (Firebase Authentication'da tutulur; şifreyi biz
  görmeyiz)
- Google veya Apple ile giriş yaptıysanız, sağlayıcının bize verdiği ad ve
  e-posta

### Sizin girdiğiniz finansal veriler
- Gelir ve harcama kayıtları, kategoriler, tarihler, notlar
- Banka hesabı adları ve bakiyeleri; girmeyi seçerseniz IBAN
- Kredi kartı adı, limiti, borcu, ekstre ve son ödeme günleri
- Kredi bilgileri, abonelikler, birikim hedefleri, bütçe limitleri
- Yatırım portföyünüz: varlık adı, adet, alış fiyatı

**Banka hesaplarınıza bağlanmıyoruz.** Uygulamanın bankalarla hiçbir
bağlantısı yoktur; tüm veriler sizin elle girdiğiniz ya da yüklediğiniz
belgelerden okunan bilgilerdir. Banka şifresi veya kart numarasının
tamamını hiçbir zaman istemeyiz; IBAN alanı isteğe bağlıdır — kart için yalnızca sizin
girdiğiniz son 4 hane saklanır.

### Cihaz ve kullanım verileri
- Bildirim gönderebilmek için cihaz bildirim kimliği (FCM token)
- Çökme raporları ve temel kullanım istatistikleri (Firebase Crashlytics,
  Firebase Analytics)

---

## 2. Verilerinizi nerede tutuyoruz

Tüm finansal verileriniz **Google Firebase (Firestore)** üzerinde, yalnızca
sizin kullanıcı kimliğinize bağlı bir alanda saklanır. Güvenlik kuralları
gereği **başka hiçbir kullanıcı sizin verilerinizi okuyamaz veya yazamaz.**

Veriler cihazınızda da önbelleğe alınır (çevrimdışı kullanım için).
Çıkış yaptığınızda bu önbellek temizlenir.

---

## 3. Yapay zekâ özellikleri (Google Gemini)

İki özellik **Google Gemini** servisine veri gönderir. İkisini de hiç
kullanmazsanız hiçbir veri Gemini'ye gitmez.

### a) Asistan (Liqra)

Asistana bir soru sorduğunuzda ya da analiz istediğinizde finansal
durumunuzun özeti gönderilir:

- Gelir/gider toplamları ve kategori dağılımı
- Hesap bakiyeleri, kart borçları, ekstre tarihleri, bankaların adları
- Portföy pozisyonlarınız ve hedefleriniz
- Piyasa fiyatları ve haber başlıkları

Bu özete adınız, e-postanız, IBAN'ınız ve kart numaranız **eklenmez**.

### b) Belge tarama (fiş, fatura, banka ekstresi)

Bir fişi, faturayı veya banka ekstresini taradığınızda ya da yüklediğinizde,
**görselin veya PDF dosyasının kendisi** metni okunup işlem kaydına
dönüştürülmek üzere Gemini'ye gönderilir. Belgenin üzerinde basılı olan her
bilgi — adınız, IBAN'ınız, kartınızın bazı haneleri, işyeri adı ve adresi
gibi — bu gönderime dahildir.

Liqra görseli veya dosyayı **saklamaz**; hesabınıza yalnızca belgeden okunan
işlem kayıtları yazılır. Paylaşmak istemediğiniz bir bilgi varsa belgeyi
yüklemeden önce kırpabilir veya işlemi elle girebilirsiniz.

### Gemini bu verileri nasıl kullanır

Gönderilen veriler yalnızca size yanıt üretmek için kullanılır. Liqra,
Gemini'yi Google'ın **ücretli API hizmeti** kapsamında kullanır; bu kapsamda
Google gönderilen içeriği kendi ürünlerini geliştirmek için kullanmaz ve
yalnızca kötüye kullanımı önleme ile yasal yükümlülükler için sınırlı süre
saklar.

---

## 4. Verilerinizi kimlerle paylaşıyoruz

**Verilerinizi satmıyoruz ve reklam amacıyla kimseyle paylaşmıyoruz.**

Kullandığımız hizmet sağlayıcılar:

| Sağlayıcı | Ne için | Ne görüyor |
|---|---|---|
| Google Firebase | Kimlik doğrulama, veritabanı, bildirim | Hesap ve finansal verileriniz |
| Google Gemini | Asistan yanıtları, belge tarama | Asistan: finansal özet (kimlik bilgisi hariç) · Tarama: yüklediğiniz belgenin görseli veya PDF'i |
| Firebase Crashlytics | Çökme raporları | Cihaz modeli, hata izi |
| Firebase Analytics | Kullanım istatistikleri | Anonim ekran görüntüleme sayıları |

---

## 5. Haklarınız (KVKK ve GDPR)

- **Erişim:** Uygulama içinden "Verileri Dışa Aktar" ile tüm işlem
  geçmişinizi CSV olarak indirebilirsiniz.
- **Silme:** Profil → "Hesabı Sil" ile hesabınızı ve tüm verilerinizi kalıcı
  olarak silebilirsiniz. Silme işlemi geri alınamaz.
- **Düzeltme:** Tüm kayıtlarınızı uygulama içinden düzenleyebilirsiniz.
- **İtiraz ve şikâyet:** Yukarıdaki e-postadan bize ulaşabilir, ayrıca Kişisel
  Verileri Koruma Kurumu'na başvurabilirsiniz.

---

## 6. Veri saklama süresi

Verileriniz hesabınız açık olduğu sürece saklanır. Hesabınızı sildiğinizde
Firestore'daki tüm kayıtlarınız ve kimlik doğrulama hesabınız silinir.

---

## 7. Çocukların gizliliği

Liqra 18 yaş altındaki kullanıcılara yönelik değildir ve bilerek çocuklardan
veri toplamayız.

---

## 8. Yatırım tavsiyesi değildir

Liqra bir yatırım danışmanlığı hizmeti değildir. Asistanın ürettiği analiz ve
yorumlar bilgilendirme amaçlıdır, yatırım tavsiyesi teşkil etmez. Yatırım
kararlarınızın sorumluluğu size aittir.

Uygulamadaki piyasa verileri üçüncü taraf kaynaklardan gelir ve gecikmeli ya
da hatalı olabilir. Banka kampanyaları örnek içeriktir; geçerliliğini
bankadan doğrulamanız gerekir.

---

## 9. Değişiklikler

Bu politikayı güncellersek uygulama içinden bildiririz ve yukarıdaki tarihi
değiştiririz.
