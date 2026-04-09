/**
 * fetchCampaigns — Banka Kampanyaları Cloud Function
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * Her gece 03:00'te (Istanbul) çalışır.
 * Büyük Türk bankalarının kampanya sayfalarından veri çeker,
 * Firestore bank_campaigns koleksiyonuna upsert eder.
 *
 * Kaynak strateji:
 *   - Önce bankaların JSON/API endpoint'leri denenir (hızlı, stabil)
 *   - API yoksa HTML parse edilir (cheerio)
 *   - Her banka için bağımsız try/catch — bir banka hata verse diğerleri çalışır
 *
 * Firestore şeması: bank_campaigns/{campaignId}
 *   {
 *     id:          string   (banka_slug + "_" + hash)
 *     bank:        string   (Garanti, İş Bankası, ...)
 *     bankSlug:    string   (garanti, isbank, ...)
 *     bankColor:   string   (#hex)
 *     title:       string
 *     description: string
 *     imageUrl:    string?
 *     detailUrl:   string
 *     endDate:     string?  (ISO 8601 veya okunabilir tarih)
 *     category:    string   (yemek, market, akaryakıt, alışveriş, seyahat, diğer)
 *     fetchedAt:   Timestamp
 *   }
 */

"use strict";

const axios            = require("axios");
const cheerio          = require("cheerio");
const crypto           = require("crypto");
const { onSchedule }   = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// ─── Banka Tanımları ──────────────────────────────────────────────────────────

const BANKS = [
  {
    slug:  "garanti",
    name:  "Garanti BBVA",
    color: "#00A850",
    fetch: fetchGaranti,
  },
  {
    slug:  "isbank",
    name:  "İş Bankası",
    color: "#005CA9",
    fetch: fetchIsbank,
  },
  {
    slug:  "akbank",
    name:  "Akbank",
    color: "#E30613",
    fetch: fetchAkbank,
  },
  {
    slug:  "yapikredi",
    name:  "Yapı Kredi",
    color: "#003087",
    fetch: fetchYapikredi,
  },
  {
    slug:  "halkbank",
    name:  "Halkbank",
    color: "#007DC3",
    fetch: fetchHalkbank,
  },
];

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
  Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
};

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
  if (t.match(/yemek|restoran|cafe|kafe|pizza|burger|yeme/))    return "yemek";
  if (t.match(/market|migros|a101|bim|carrefour|şok/))          return "market";
  if (t.match(/akaryakıt|benzin|opet|petrol|shell|bp/))         return "akaryakıt";
  if (t.match(/seyahat|uçuş|otel|thy|pegasus|tatil/))           return "seyahat";
  if (t.match(/alışveriş|trendyol|hepsiburada|amazon|teknosa/)) return "alışveriş";
  if (t.match(/fatura|elektrik|su|doğalgaz|internet/))          return "fatura";
  return "diğer";
}

// ─── Banka Çekiciler ──────────────────────────────────────────────────────────

/** Garanti BBVA — bonus.com.tr API */
async function fetchGaranti() {
  const res = await axios.get(
    "https://www.garantibbva.com.tr/kampanyalar",
    { headers: HEADERS, timeout: 15000 }
  );
  const $ = cheerio.load(res.data);
  const campaigns = [];

  $(".campaign-card, .kampanya-kart, article.card, .kampanya-item").each((_, el) => {
    const title       = $(el).find("h2, h3, .title, .baslik").first().text().trim();
    const description = $(el).find("p, .description, .aciklama").first().text().trim();
    const imageUrl    = $(el).find("img").first().attr("src") || "";
    const linkPath    = $(el).find("a").first().attr("href") || "";
    const detailUrl   = linkPath.startsWith("http")
      ? linkPath
      : `https://www.garantibbva.com.tr${linkPath}`;
    const endDate     = $(el).find(".tarih, .end-date, .bitis").first().text().trim();

    if (!title || title.length < 3) return;
    campaigns.push({ title, description, imageUrl, detailUrl, endDate });
  });

  // Fallback: meta açıklaması olan linkler
  if (campaigns.length === 0) {
    $("a[href*='kampanya']").each((_, el) => {
      const title = $(el).text().trim();
      if (title.length < 5) return;
      const href = $(el).attr("href") || "";
      const detailUrl = href.startsWith("http")
        ? href
        : `https://www.garantibbva.com.tr${href}`;
      campaigns.push({ title, description: "", imageUrl: "", detailUrl, endDate: "" });
    });
  }

  return campaigns.slice(0, 20);
}

/** İş Bankası */
async function fetchIsbank() {
  const res = await axios.get(
    "https://www.isbank.com.tr/kampanyalar",
    { headers: HEADERS, timeout: 15000 }
  );
  const $ = cheerio.load(res.data);
  const campaigns = [];

  $(".campaign-item, .kampanya, .card, [class*='campaign']").each((_, el) => {
    const title       = $(el).find("h2, h3, h4, .title").first().text().trim();
    const description = $(el).find("p, .desc, .text").first().text().trim();
    const imageUrl    = $(el).find("img").first().attr("src") || "";
    const linkPath    = $(el).find("a").first().attr("href") || "";
    const detailUrl   = linkPath.startsWith("http")
      ? linkPath
      : `https://www.isbank.com.tr${linkPath}`;
    const endDate     = $(el).find("[class*='date'], [class*='tarih']").first().text().trim();

    if (!title || title.length < 3) return;
    campaigns.push({ title, description, imageUrl, detailUrl, endDate });
  });

  return campaigns.slice(0, 20);
}

/** Akbank */
async function fetchAkbank() {
  const res = await axios.get(
    "https://www.akbank.com/tr-tr/bireysel/kampanyalar",
    { headers: HEADERS, timeout: 15000 }
  );
  const $ = cheerio.load(res.data);
  const campaigns = [];

  $(".campaign-card, .kampanya-card, .card, [class*='Campaign']").each((_, el) => {
    const title       = $(el).find("h2, h3, .title, .heading").first().text().trim();
    const description = $(el).find("p, .description").first().text().trim();
    const imageUrl    = $(el).find("img").first().attr("src") || "";
    const linkPath    = $(el).find("a").first().attr("href") || "";
    const detailUrl   = linkPath.startsWith("http")
      ? linkPath
      : `https://www.akbank.com${linkPath}`;
    const endDate     = $(el).find("[class*='date'], [class*='Date']").first().text().trim();

    if (!title || title.length < 3) return;
    campaigns.push({ title, description, imageUrl, detailUrl, endDate });
  });

  return campaigns.slice(0, 20);
}

/** Yapı Kredi */
async function fetchYapikredi() {
  const res = await axios.get(
    "https://www.yapikredi.com.tr/kampanyalar",
    { headers: HEADERS, timeout: 15000 }
  );
  const $ = cheerio.load(res.data);
  const campaigns = [];

  $(".campaign, .card, [class*='campaign'], [class*='kampanya']").each((_, el) => {
    const title       = $(el).find("h2, h3, h4, .title").first().text().trim();
    const description = $(el).find("p, .description, .text").first().text().trim();
    const imageUrl    = $(el).find("img").first().attr("src") || "";
    const linkPath    = $(el).find("a").first().attr("href") || "";
    const detailUrl   = linkPath.startsWith("http")
      ? linkPath
      : `https://www.yapikredi.com.tr${linkPath}`;
    const endDate     = $(el).find("[class*='date'], [class*='tarih']").first().text().trim();

    if (!title || title.length < 3) return;
    campaigns.push({ title, description, imageUrl, detailUrl, endDate });
  });

  return campaigns.slice(0, 20);
}

/** Halkbank */
async function fetchHalkbank() {
  const res = await axios.get(
    "https://www.halkbank.com.tr/kampanya",
    { headers: HEADERS, timeout: 15000 }
  );
  const $ = cheerio.load(res.data);
  const campaigns = [];

  $(".card, .kampanya, [class*='campaign']").each((_, el) => {
    const title       = $(el).find("h2, h3, h4, .title, .baslik").first().text().trim();
    const description = $(el).find("p, .description").first().text().trim();
    const imageUrl    = $(el).find("img").first().attr("src") || "";
    const linkPath    = $(el).find("a").first().attr("href") || "";
    const detailUrl   = linkPath.startsWith("http")
      ? linkPath
      : `https://www.halkbank.com.tr${linkPath}`;
    const endDate     = $(el).find("[class*='date'], [class*='tarih']").first().text().trim();

    if (!title || title.length < 3) return;
    campaigns.push({ title, description, imageUrl, detailUrl, endDate });
  });

  return campaigns.slice(0, 20);
}

// ─── Firestore Yazıcı ─────────────────────────────────────────────────────────

async function upsertCampaigns(db, bankMeta, rawCampaigns) {
  if (!rawCampaigns || rawCampaigns.length === 0) return 0;

  const col       = db.collection("bank_campaigns");
  const fetchedAt = Timestamp.now();
  let   written   = 0;

  const batch = db.batch();

  for (const raw of rawCampaigns) {
    if (!raw.title) continue;
    const id  = makeId(bankMeta.slug, raw.title);
    const ref = col.doc(id);

    batch.set(ref, {
      id,
      bank:        bankMeta.name,
      bankSlug:    bankMeta.slug,
      bankColor:   bankMeta.color,
      title:       raw.title,
      description: raw.description || "",
      imageUrl:    raw.imageUrl    || "",
      detailUrl:   raw.detailUrl   || "",
      endDate:     raw.endDate     || "",
      category:    detectCategory(`${raw.title} ${raw.description}`),
      fetchedAt,
    }, { merge: true });

    written++;
  }

  await batch.commit();
  return written;
}

// ─── Cloud Function ───────────────────────────────────────────────────────────

exports.fetchCampaigns = onSchedule(
  {
    schedule:       "0 3 * * *",   // Her gece 03:00
    timeZone:       "Europe/Istanbul",
    memory:         "512MiB",
    timeoutSeconds: 300,
    region:         "europe-west1",
  },
  async () => {
    const db = getFirestore();
    const results = [];

    for (const bank of BANKS) {
      try {
        console.log(`[campaigns] ${bank.name} çekiliyor...`);
        const raw     = await bank.fetch();
        const written = await upsertCampaigns(db, bank, raw);
        console.log(`[campaigns] ✓ ${bank.name}: ${written} kampanya`);
        results.push({ bank: bank.name, written, ok: true });
      } catch (err) {
        console.error(`[campaigns] ✗ ${bank.name}: ${err.message}`);
        results.push({ bank: bank.name, written: 0, ok: false, error: err.message });
      }
    }

    const total = results.reduce((s, r) => s + r.written, 0);
    console.log(`[campaigns] Tamamlandı — ${total} toplam kampanya yazıldı`);

    // Son çalışma meta
    await db.doc("meta/campaigns").set({
      lastRun:   Timestamp.now(),
      results,
      total,
    });
  }
);
