/**
 * fetchCampaigns — Banka Kampanyaları Cloud Function
 *
 * ── Verinin durumu (ÖNEMLİ) ────────────────────────────────────────────────
 * Şu an yazılan kampanyaların TAMAMI seed (örnek) veridir; hiçbiri gerçek
 * banka API'sinden gelmez. Bu yüzden her kayıt `isSample: true` ile
 * damgalanır:
 *   • Arayüz "Örnek" rozeti gösterir.
 *   • Asistan bunları bildirime ÇEVİRMEZ (bkz. CampaignMatcher.toInsights) ve
 *     modele "doğrulanmamış" diye bildirir.
 *
 * Denenen ve ÇALIŞMAYAN canlı kaynaklar (2026-09-02'de doğrulandı):
 *   • https://www.garantibbva.com.tr/api/v1/campaigns  → 404
 *   • https://www.garantibbva.com.tr/kampanyalar.json  → 200 ama içerik AEM
 *     sayfa metadatası ({"jcr:primaryType":"cq:Page"}), kampanya yok.
 *     `.infinity.json` yalnızca `.0.json` işaretçisi döndürüyor; derinlik
 *     kapalı, veri çekilemiyor.
 *
 * Bu deneme kodu kaldırıldı: her gün iki boş HTTP isteği atıp uyarı logluyor,
 * karşılığında hiçbir zaman veri getirmiyordu. Gerçek kampanya verisi için
 * bir bankanın açık API'si ya da lisanslı bir kampanya sağlayıcısı gerekir.
 */

"use strict";

const { onSchedule }   = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const crypto           = require("crypto");

// ─── Yardımcılar ─────────────────────────────────────────────────────────────

function makeId(bankSlug, title) {
  const hash = crypto
    .createHash("md5")
    .update(`${bankSlug}_${title}`)
    .digest("hex")
    .slice(0, 8);
  return `${bankSlug}_${hash}`;
}

function detectCategory(text) {
  const t = (text || "").toLowerCase();
  if (t.match(/yemek|restoran|cafe|kafe|pizza|burger|yeme/))     return "yemek";
  if (t.match(/market|migros|a101|bim|carrefour|şok|groceri/))   return "market";
  if (t.match(/akaryakıt|benzin|opet|petrol|shell|bp|yakıt/))    return "akaryakit";
  if (t.match(/seyahat|uçuş|otel|thy|pegasus|tatil|bilet/))      return "seyahat";
  if (t.match(/alışveriş|trendyol|hepsiburada|amazon|teknosa|shopping/)) return "alisveris";
  if (t.match(/fatura|elektrik|su|doğalgaz|internet|gsm|faturai/)) return "fatura";
  return "diger";
}

// ─── Seed Data (Güvenilir Fallback) ─────────────────────────────────────────

const SEED_CAMPAIGNS = [
  // ── Garanti BBVA ────────────────────────────────────────────────────────
  {
    bank: "Garanti BBVA", bankSlug: "garanti", bankColor: "#00A850",
    title: "%25 Bonus — Yemek Kategorisinde",
    description: "Garanti BBVA kredi kartıyla seçili yemek platformlarında %25'e varan bonus kazanın. Yemeksepeti ve Getir geçerlidir.",
    detailUrl: "https://www.garantibbva.com.tr/kampanyalar",
    category: "yemek", endDate: "",
  },
  {
    bank: "Garanti BBVA", bankSlug: "garanti", bankColor: "#00A850",
    title: "Akaryakıtta %10 Bonus",
    description: "BP ve Opet istasyonlarında Garanti BBVA Bonus Card ile ödemelerinizde %10 bonus kazanın.",
    detailUrl: "https://www.garantibbva.com.tr/kampanyalar",
    category: "akaryakit", endDate: "",
  },
  {
    bank: "Garanti BBVA", bankSlug: "garanti", bankColor: "#00A850",
    title: "Trendyol'da 200 TL Bonus",
    description: "Garanti BBVA kartıyla Trendyol'da 500 TL ve üzeri alışverişlerinizde 200 TL bonus kazanın.",
    detailUrl: "https://www.garantibbva.com.tr/kampanyalar",
    category: "alisveris", endDate: "",
  },
  {
    bank: "Garanti BBVA", bankSlug: "garanti", bankColor: "#00A850",
    title: "Market Alışverişinde %15 Bonus",
    description: "Migros, CarrefourSA ve Hakmar'da kartınızla yapacağınız alışverişlerde %15 bonus kazanın.",
    detailUrl: "https://www.garantibbva.com.tr/kampanyalar",
    category: "market", endDate: "",
  },

  // ── İş Bankası ───────────────────────────────────────────────────────────
  {
    bank: "İş Bankası", bankSlug: "isbank", bankColor: "#005CA9",
    title: "Maximum Card ile Uçuşta %20 İndirim",
    description: "Türk Hava Yolları ve Pegasus uçuş biletlerinde Maximum Card sahiplerine özel %20 indirim fırsatı.",
    detailUrl: "https://www.isbank.com.tr/kampanyalar",
    category: "seyahat", endDate: "",
  },
  {
    bank: "İş Bankası", bankSlug: "isbank", bankColor: "#005CA9",
    title: "Hepsiburada'da 300 TL MaxiPuan",
    description: "İş Bankası Maximum Card ile Hepsiburada'da 750 TL ve üzeri alışverişte 300 TL MaxiPuan hediye.",
    detailUrl: "https://www.isbank.com.tr/kampanyalar",
    category: "alisveris", endDate: "",
  },
  {
    bank: "İş Bankası", bankSlug: "isbank", bankColor: "#005CA9",
    title: "Fatura Ödemelerinde 50 TL Bonus",
    description: "Otomatik fatura talimatı veren Maximum Card müşterilerine her ay 50 TL MaxiPuan.",
    detailUrl: "https://www.isbank.com.tr/kampanyalar",
    category: "fatura", endDate: "",
  },
  {
    bank: "İş Bankası", bankSlug: "isbank", bankColor: "#005CA9",
    title: "A101 ve BİM'de %12 İndirim",
    description: "Maximum Card ile A101 ve BİM market alışverişlerinde %12 MaxiPuan kazanın.",
    detailUrl: "https://www.isbank.com.tr/kampanyalar",
    category: "market", endDate: "",
  },

  // ── Akbank ───────────────────────────────────────────────────────────────
  {
    bank: "Akbank", bankSlug: "akbank", bankColor: "#E30613",
    title: "Axess ile Teknolojide %10 Taksit",
    description: "Axess kredi kartıyla teknoloji mağazalarında 12 aya kadar taksit ve %10 bonus fırsatı.",
    detailUrl: "https://www.akbank.com/kampanyalar",
    category: "alisveris", endDate: "",
  },
  {
    bank: "Akbank", bankSlug: "akbank", bankColor: "#E30613",
    title: "Yemeklerde Her Cuma %30 Bonus",
    description: "Her Cuma günü Axess Card ile yemek uygulamalarında yapacağınız ödemelerde %30 bonus kazanın.",
    detailUrl: "https://www.akbank.com/kampanyalar",
    category: "yemek", endDate: "",
  },
  {
    bank: "Akbank", bankSlug: "akbank", bankColor: "#E30613",
    title: "Shell İstasyonlarında %8 İndirim",
    description: "Axess Card sahiplerine Shell akaryakıt istasyonlarında %8 bonus kampanyası.",
    detailUrl: "https://www.akbank.com/kampanyalar",
    category: "akaryakit", endDate: "",
  },
  {
    bank: "Akbank", bankSlug: "akbank", bankColor: "#E30613",
    title: "Tatil Rezervasyonlarında Özel Fiyat",
    description: "Axess Card ile Jolly Tur ve Setur rezervasyonlarında erken rezervasyon avantajı.",
    detailUrl: "https://www.akbank.com/kampanyalar",
    category: "seyahat", endDate: "",
  },

  // ── Yapı Kredi ───────────────────────────────────────────────────────────
  {
    bank: "Yapı Kredi", bankSlug: "yapikredi", bankColor: "#003087",
    title: "World Card ile 500 TL WorldPuan",
    description: "Yapı Kredi World Card sahiplerine Trendyol ve n11'de 1000 TL üzeri alışverişte 500 TL WorldPuan.",
    detailUrl: "https://www.yapikredi.com.tr/kampanyalar",
    category: "alisveris", endDate: "",
  },
  {
    bank: "Yapı Kredi", bankSlug: "yapikredi", bankColor: "#003087",
    title: "Araç Kiralamada %15 WorldPuan",
    description: "Avis ve Budget araç kiralama firmalarında World Card ile ödeme yapın, %15 WorldPuan kazanın.",
    detailUrl: "https://www.yapikredi.com.tr/kampanyalar",
    category: "seyahat", endDate: "",
  },
  {
    bank: "Yapı Kredi", bankSlug: "yapikredi", bankColor: "#003087",
    title: "Migros'ta Haftasonu %20 Bonus",
    description: "Cumartesi ve Pazar günleri World Card ile Migros alışverişlerinizde %20 WorldPuan.",
    detailUrl: "https://www.yapikredi.com.tr/kampanyalar",
    category: "market", endDate: "",
  },
  {
    bank: "Yapı Kredi", bankSlug: "yapikredi", bankColor: "#003087",
    title: "Doğalgaz Faturasında 100 TL İndirim",
    description: "İGDAŞ ve EnerjiSA faturalarını otomatik ödeyen World Card sahiplerine 100 TL kredi.",
    detailUrl: "https://www.yapikredi.com.tr/kampanyalar",
    category: "fatura", endDate: "",
  },

  // ── Halkbank ─────────────────────────────────────────────────────────────
  {
    bank: "Halkbank", bankSlug: "halkbank", bankColor: "#007DC3",
    title: "Paraf Card ile Market Alışverişinde %10 Puan",
    description: "Halkbank Paraf Card ile A101, BİM ve Migros'ta %10 Paraf puan kazanın.",
    detailUrl: "https://www.halkbank.com.tr/kampanya",
    category: "market", endDate: "",
  },
  {
    bank: "Halkbank", bankSlug: "halkbank", bankColor: "#007DC3",
    title: "Esnaf Destekleme Kampanyası",
    description: "Halkbank iş yeri POS sahiplerine ödeme komisyonlarında özel indirim fırsatı.",
    detailUrl: "https://www.halkbank.com.tr/kampanya",
    category: "diger", endDate: "",
  },
  {
    bank: "Halkbank", bankSlug: "halkbank", bankColor: "#007DC3",
    title: "Akaryakıtta Her Doldurmada Para Kazanın",
    description: "Paraf Card ile petrol ofisi istasyonlarında her dolurmada %5 Paraf puan iade.",
    detailUrl: "https://www.halkbank.com.tr/kampanya",
    category: "akaryakit", endDate: "",
  },
  {
    bank: "Halkbank", bankSlug: "halkbank", bankColor: "#007DC3",
    title: "Yurt İçi Tatilde %20 Paraf Puan",
    description: "Touristica ve ETS otel rezervasyonlarında Paraf Card ile %20 Paraf puan kazanma fırsatı.",
    detailUrl: "https://www.halkbank.com.tr/kampanya",
    category: "seyahat", endDate: "",
  },
];

// ─── Firestore Upsert ─────────────────────────────────────────────────────────

async function upsertAll(db, campaigns) {
  const col       = db.collection("bank_campaigns");
  const fetchedAt = Timestamp.now();
  const batch     = db.batch();
  const liveIds   = new Set();

  for (const c of campaigns) {
    if (!c.title) continue;
    const id = makeId(c.bankSlug, c.title);
    liveIds.add(id);

    batch.set(col.doc(id), {
      id,
      bank:        c.bank,
      bankSlug:    c.bankSlug,
      bankColor:   c.bankColor,
      title:       c.title,
      description: c.description || "",
      imageUrl:    c.imageUrl    || "",
      detailUrl:   c.detailUrl   || "",
      endDate:     c.endDate     || "",
      category:    c.category || detectCategory(`${c.title} ${c.description}`),
      // Seed kayıtları gerçek banka API'sinden gelmez — istemci bunları
      // "örnek" olarak etiketler ki doğrulanmış kampanya sanılmasın.
      isSample:    c.isSample === true,
      fetchedAt,
    }, { merge: true });
  }

  await batch.commit();
  return liveIds;
}

// ─── Artık Var Olmayan Kampanyaları Sil ───────────────────────────────────────
//
// Upsert yalnızca yazıyordu; kaynaktan kaldırılan bir kampanya Firestore'da
// sonsuza kadar kalıyor ve kullanıcıya bitmiş bir teklif olarak gösteriliyordu.
// Başlığı değişen kampanyalar da yeni bir id aldığı için eskisi öksüz kalıyordu.
async function removeStale(db, liveIds) {
  const snap = await db.collection("bank_campaigns").get();
  const stale = snap.docs.filter((d) => !liveIds.has(d.id));
  if (stale.length === 0) return 0;

  const BATCH_SIZE = 400;
  for (let i = 0; i < stale.length; i += BATCH_SIZE) {
    const batch = db.batch();
    stale.slice(i, i + BATCH_SIZE).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  return stale.length;
}

// ─── Cloud Function ───────────────────────────────────────────────────────────

exports.fetchCampaigns = onSchedule(
  {
    schedule:       "0 3 * * *",
    timeZone:       "Europe/Istanbul",
    memory:         "256MiB",
    timeoutSeconds: 120,
    region:         "europe-west1",
  },
  async () => {
    const db = getFirestore();

    // Tüm kayıtlar örnek veridir — canlı banka kaynağı bağlı değil.
    const all = SEED_CAMPAIGNS.map((c) => ({ ...c, isSample: true }));

    const liveIds = await upsertAll(db, all);
    const removed = await removeStale(db, liveIds);

    console.log(
      `[campaigns] ${liveIds.size} kampanya yazıldı, ${removed} eski kayıt silindi.`
    );

    await db.doc("meta/campaigns").set({
      lastRun: Timestamp.now(),
      total:   liveIds.size,
      // Canlı kaynak bağlanınca false olacak; arayüz ve asistan buna bakar.
      allSamples: true,
    }, { merge: true });
  }
);
