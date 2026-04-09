/**
 * fetchNews — saatlik çalışır, finansal haber RSS'lerini parse eder
 * Firestore: news/{id}
 * Europe-west1 region, Secret Manager'dan key gerekmez (herkese açık RSS)
 */

"use strict";

const { onSchedule }         = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const Parser                 = require("rss-parser");

const parser = new Parser({
  timeout: 10000,
  headers: {
    "User-Agent":
      "Mozilla/5.0 (compatible; LiqraBot/1.0; +https://liqra.app)",
  },
});

// ── RSS Kaynakları ────────────────────────────────────────────────────────────
const FEEDS = [
  {
    name:   "Bloomberg HT",
    url:    "https://www.bloomberght.com/rss",
    color:  "#FF6B00",
    slug:   "bloomberght",
  },
  {
    name:   "Mynet Finans",
    url:    "https://finans.mynet.com/rss/haberler/",
    color:  "#0066CC",
    slug:   "mynet",
  },
  {
    name:   "Investing.com TR",
    url:    "https://tr.investing.com/rss/news.rss",
    color:  "#E63946",
    slug:   "investing",
  },
  {
    name:   "Dünya Gazetesi",
    url:    "https://www.dunya.com/rss.xml",
    color:  "#1A1A2E",
    slug:   "dunya",
  },
  {
    name:   "Para Analiz",
    url:    "https://www.paraanaliz.com/feed/",
    color:  "#2E8B57",
    slug:   "paraanaliz",
  },
];

// ── Kategori Tespiti ──────────────────────────────────────────────────────────
const CATEGORY_RULES = [
  { cat: "borsa",    re: /bist|borsa|hisse|endeks|xu100|xu030|rally|düşüş|yükseliş/i },
  { cat: "döviz",    re: /dolar|euro|eur|usd|kur|döviz|sterling|yen|frank/i },
  { cat: "altin",    re: /altın|gram altın|çeyrek|ons|gold/i },
  { cat: "kripto",   re: /bitcoin|btc|ethereum|eth|kripto|crypto|coin/i },
  { cat: "faiz",     re: /faiz|tcmb|merkez bankası|politika faizi|enflasyon/i },
  { cat: "ekonomi",  re: /gdp|gsyih|büyüme|ihracat|ithalat|cari açık|bütçe/i },
  { cat: "sirket",   re: /halka arz|temettü|kar açıkladı|gelir|ciro|bilanço/i },
];

function detectCategory(title, description) {
  const text = `${title} ${description}`.toLowerCase();
  for (const { cat, re } of CATEGORY_RULES) {
    if (re.test(text)) return cat;
  }
  return "genel";
}

// ── ID Oluştur ────────────────────────────────────────────────────────────────
function makeId(slug, link) {
  // URL'den sayısal ID veya son path segment
  try {
    const url  = new URL(link);
    const parts = url.pathname.split("/").filter(Boolean);
    const last  = parts[parts.length - 1] || "";
    // Sayısal ID varsa kullan, yoksa hash-lite
    const clean = last.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 40);
    return `${slug}_${clean || Date.now()}`;
  } catch {
    return `${slug}_${Date.now()}`;
  }
}

// ── Tek Feed Parse ────────────────────────────────────────────────────────────
async function parseFeed(feed) {
  try {
    const parsed = await parser.parseURL(feed.url);
    const items  = (parsed.items || []).slice(0, 20); // son 20 haber

    return items.map((item) => {
      const title       = (item.title       || "").trim();
      const description = (item.contentSnippet || item.summary || "").trim();
      const link        = item.link || item.guid || "";
      const pubDate     = item.isoDate ? new Date(item.isoDate) : new Date();
      const imageUrl    = extractImage(item);

      return {
        id:          makeId(feed.slug, link),
        source:      feed.name,
        sourceSlug:  feed.slug,
        sourceColor: feed.color,
        title,
        description: description.slice(0, 300),
        url:         link,
        imageUrl,
        category:    detectCategory(title, description),
        pubDate:     Timestamp.fromDate(pubDate),
        fetchedAt:   Timestamp.now(),
      };
    });
  } catch (err) {
    console.warn(`[fetchNews] ${feed.name} parse hatası:`, err.message);
    return [];
  }
}

// ── Resim URL çıkar ───────────────────────────────────────────────────────────
function extractImage(item) {
  // media:content veya enclosure
  if (item["media:content"]?.["$"]?.url) return item["media:content"]["$"].url;
  if (item.enclosure?.url)               return item.enclosure.url;
  // content içinde <img src="...">
  const content = item.content || item["content:encoded"] || "";
  const m = content.match(/<img[^>]+src=["']([^"']+)["']/i);
  return m ? m[1] : "";
}

// ── Firestore Upsert ──────────────────────────────────────────────────────────
async function upsertNews(articles) {
  const db = getFirestore();
  const col = db.collection("news");

  // Batch'ler 500 dokümana kadar
  const BATCH_SIZE = 400;
  let count = 0;

  for (let i = 0; i < articles.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = articles.slice(i, i + BATCH_SIZE);

    for (const art of chunk) {
      if (!art.title) continue;
      const ref = col.doc(art.id);
      batch.set(ref, art, { merge: true });
      count++;
    }
    await batch.commit();
  }

  // Meta güncelle
  await db.collection("meta").doc("news").set({
    lastUpdated:  Timestamp.now(),
    articleCount: count,
  }, { merge: true });

  console.log(`[fetchNews] ${count} haber Firestore'a yazıldı.`);
}

// ── Eski Haberleri Temizle (7 günden eski) ────────────────────────────────────
async function cleanOldNews() {
  const db       = getFirestore();
  const cutoff   = new Date();
  cutoff.setDate(cutoff.getDate() - 7);

  const snap = await db.collection("news")
    .where("pubDate", "<", Timestamp.fromDate(cutoff))
    .limit(200)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  console.log(`[fetchNews] ${snap.size} eski haber silindi.`);
}

// ── Cloud Function ────────────────────────────────────────────────────────────
const fetchNews = onSchedule(
  {
    schedule:        "0 * * * *",  // Her saat başı
    timeZone:        "Europe/Istanbul",
    region:          "europe-west1",
    memory:          "256MiB",
    timeoutSeconds:  120,
  },
  async () => {
    console.log("[fetchNews] Başlıyor...");

    const results = await Promise.allSettled(FEEDS.map(parseFeed));
    const all = results
      .filter((r) => r.status === "fulfilled")
      .flatMap((r) => r.value);

    // Tekrarları id'ye göre de-duplicate et
    const seen = new Set();
    const unique = all.filter((a) => {
      if (seen.has(a.id)) return false;
      seen.add(a.id);
      return true;
    });

    console.log(`[fetchNews] ${unique.length} benzersiz haber bulundu.`);

    await upsertNews(unique);
    await cleanOldNews();

    console.log("[fetchNews] Tamamlandı.");
  }
);

module.exports = { fetchNews };
