/**
 * fetchNews — saatlik çalışır, finansal haber RSS'lerini parse eder
 * Firestore: news/{id}
 * Europe-west1 region, Secret Manager'dan key gerekmez (herkese açık RSS)
 */

"use strict";

const { onSchedule }         = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const Parser                 = require("rss-parser");
const crypto                 = require("crypto");

const parser = new Parser({
  timeout: 10000,
  headers: {
    "User-Agent":
      "Mozilla/5.0 (compatible; LiqraBot/1.0; +https://liqra.app)",
  },
});

// ── RSS Kaynakları ────────────────────────────────────────────────────────────
//
// Kaynaklar 2026-09-02'de tek tek doğrulandı. Kaldırılanlar:
//   • Mynet Finans      (finans.mynet.com/rss/haberler/)  → 404
//   • Dünya Gazetesi    (dunya.com/rss.xml)               → 404
//   • Para Analiz       (paraanaliz.com/feed)             → HTML hata sayfası
//
// Bunlar sessizce başarısız oluyordu: parseFeed hatayı yutup boş dizi
// döndürdüğü için haber akışı %40 kapasiteyle çalışıyor ama loglarda sorun
// görünmüyordu. Artık çalışmayan kaynak sayısı log'a yazılır.
const FEEDS = [
  {
    name:   "Bloomberg HT",
    url:    "https://www.bloomberght.com/rss",
    color:  "#FF6B00",
    slug:   "bloomberght",
  },
  {
    name:   "Investing.com TR",
    url:    "https://tr.investing.com/rss/news.rss",
    color:  "#E63946",
    slug:   "investing",
  },
  {
    name:   "TRT Haber Ekonomi",
    url:    "https://www.trthaber.com/ekonomi_articles.rss",
    color:  "#004B93",
    slug:   "trthaber",
  },
  {
    name:   "NTV Ekonomi",
    url:    "https://www.ntv.com.tr/ekonomi.rss",
    color:  "#C8102E",
    slug:   "ntv",
  },
  {
    name:   "Hürriyet Ekonomi",
    url:    "https://www.hurriyet.com.tr/rss/ekonomi",
    color:  "#E4002B",
    slug:   "hurriyet",
  },
];

// ── Kategori Tespiti ──────────────────────────────────────────────────────────
// Slug'lar ASCII yazılır: istemci tarafındaki enum adları (doviz, sirket,
// altin) ve Firestore filtreleri bu biçimi bekler. Eskiden "döviz" Türkçe
// karakterle yazılıyordu; kategoriye göre Firestore sorgusu hiçbir sonuç
// döndürmezdi. Eski kayıtlar normalizeCategorySlug ile hâlâ tanınır.
const CATEGORY_RULES = [
  { cat: "borsa",    re: /bist|borsa|hisse|endeks|xu100|xu030|rally|düşüş|yükseliş/i },
  { cat: "doviz",    re: /dolar|euro|eur|usd|kur|döviz|sterling|yen|frank/i },
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
//
// Bağlantının tamamının hash'i kullanılır. Eski yöntem URL'nin son path
// parçasını alıp 40 karaktere kırpıyordu ve iki hataya yol açıyordu:
//
//   1. Ayırt edici sayısal id genelde slug'ın SONUNDA olur
//      (".../orta-vadeli-program-pazar-gunu-aciklanacak-955675.html").
//      40 karakterde kırpılınca o id düşüyor ve benzer başlıklı iki haber
//      AYNI dokümana yazılıyordu — biri diğerini eziyordu.
//   2. Path'i olmayan veya query string'e dayanan bağlantılarda
//      (".../news.php?id=123") tüm haberler tek bir id'ye çöküyordu.
//
// Fallback olarak Date.now() kullanmak da yanlıştı: aynı haber her saat yeni
// bir id ile tekrar yazılıp koleksiyonu şişiriyordu.
function makeId(slug, link, title) {
  const seed = (link || "").trim() || (title || "").trim();
  if (!seed) return null; // ne bağlantı ne başlık var — bu haber atlanır
  const hash = crypto.createHash("md5").update(seed).digest("hex").slice(0, 16);
  return `${slug}_${hash}`;
}

// ── Yayın tarihi ──────────────────────────────────────────────────────────────
//
// isoDate yoksa pubDate string'i denenir. Hiçbiri yoksa null döner ve doküman
// pubDate ALANI OLMADAN yazılır; mevcut kayıtta duran tarih korunur.
// Eskiden bu durumda `new Date()` yazılıyordu: tarihsiz haberlerin pubDate'i
// her saat güncelleniyor, haber listenin tepesine yapışıp kalıyor ve 7 günlük
// temizliğe hiç takılmıyordu.
function parsePubDate(item) {
  const raw = item.isoDate || item.pubDate || item.published || "";
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

// ── Tek Feed Parse ────────────────────────────────────────────────────────────
async function parseFeed(feed) {
  const parsed = await parser.parseURL(feed.url);
  const items  = (parsed.items || []).slice(0, 20); // son 20 haber

  return items
    .map((item) => {
      const title       = (item.title || "").trim();
      const description = (item.contentSnippet || item.summary || "").trim();
      const link        = item.link || item.guid || "";
      const id          = makeId(feed.slug, link, title);
      if (!id || !title) return null;

      const pubDate = parsePubDate(item);

      const doc = {
        id,
        source:      feed.name,
        sourceSlug:  feed.slug,
        sourceColor: feed.color,
        title,
        description: description.slice(0, 300),
        url:         link,
        imageUrl:    extractImage(item),
        category:    detectCategory(title, description),
        fetchedAt:   Timestamp.now(),
      };

      // Tarih bilinmiyorsa alan hiç yazılmaz — mevcut kayıttaki tarih korunur.
      if (pubDate) doc.pubDate = Timestamp.fromDate(pubDate);
      return doc;
    })
    .filter(Boolean);
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

/// Tarihi bilinmeyen haberlere YALNIZCA ilk yazımda "şimdi" damgası atar.
///
/// Yayın tarihi olmayan bir habere her turda `now` yazmak onu listenin
/// tepesine yapıştırır ve 7 günlük temizlikten kaçırır. Tarihi hiç yazmamak
/// ise Firestore'da `orderBy('pubDate')` sorgusunun o dokümanı görmemesine
/// yol açar — haber hiç görünmez. Doğrusu: tarih ilk görülmede bir kez yazılır.
///
/// Doğrulanan beş kaynağın hepsi tarih veriyor, bu yüzden liste normalde boş
/// kalır ve ek okuma maliyeti oluşmaz.
async function stampMissingDates(db, col, articles) {
  const dateless = articles.filter((a) => !a.pubDate);
  if (dateless.length === 0) return;

  const refs     = dateless.map((a) => col.doc(a.id));
  const existing = await db.getAll(...refs);
  const now      = Timestamp.now();

  existing.forEach((snap, i) => {
    if (!snap.exists) dateless[i].pubDate = now;
  });
}

async function upsertNews(articles, failedFeeds = []) {
  const db  = getFirestore();
  const col = db.collection("news");

  await stampMissingDates(db, col, articles);

  // Batch'ler 500 dokümana kadar
  const BATCH_SIZE = 400;
  let count = 0;

  for (let i = 0; i < articles.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = articles.slice(i, i + BATCH_SIZE);

    for (const art of chunk) {
      batch.set(col.doc(art.id), art, { merge: true });
      count++;
    }
    await batch.commit();
  }

  await db.collection("meta").doc("news").set({
    lastUpdated:  Timestamp.now(),
    articleCount: count,
    // Kaynak sağlığı Firestore'a da yazılır; ölü bir feed'i fark etmek için
    // Cloud Functions loglarına bakmak gerekmesin.
    activeFeeds:  FEEDS.length - failedFeeds.length,
    totalFeeds:   FEEDS.length,
    failedFeeds,
  }, { merge: true });

  console.log(`[fetchNews] ${count} haber Firestore'a yazıldı.`);
}

// ── Eski Haberleri Temizle (7 günden eski) ────────────────────────────────────
//
// Tek turda 200 doküman siliniyordu; bu, biriken arşivi asla eritemeyecek
// kadar azdı. Artık silinecek bir şey kalmayana kadar döner (üst sınırla).
async function cleanOldNews() {
  const db     = getFirestore();
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);

  const BATCH = 400;
  const MAX_ROUNDS = 10; // güvenlik freni — tur başına en fazla 4.000 silme
  let deleted = 0;

  for (let round = 0; round < MAX_ROUNDS; round++) {
    const snap = await db.collection("news")
      .where("pubDate", "<", Timestamp.fromDate(cutoff))
      .limit(BATCH)
      .get();

    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;

    if (snap.size < BATCH) break;
  }

  if (deleted > 0) console.log(`[fetchNews] ${deleted} eski haber silindi.`);
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

    // Çalışmayan kaynakları GÖRÜNÜR yap. Eskiden parseFeed hatayı kendi içinde
    // yutuyordu; üç kaynak aylarca ölü kaldığı hâlde log'da iz yoktu.
    const failed = [];
    const all = [];
    results.forEach((r, i) => {
      if (r.status === "fulfilled" && r.value.length > 0) {
        all.push(...r.value);
      } else {
        const reason = r.status === "rejected" ? r.reason?.message : "0 haber";
        failed.push(`${FEEDS[i].name} (${reason})`);
      }
    });

    if (failed.length > 0) {
      console.error(
        `[fetchNews] ${failed.length}/${FEEDS.length} kaynak ÇALIŞMIYOR: ` +
        failed.join(", ")
      );
    }

    // Tekrarları id'ye göre de-duplicate et
    const seen = new Set();
    const unique = all.filter((a) => {
      if (seen.has(a.id)) return false;
      seen.add(a.id);
      return true;
    });

    console.log(
      `[fetchNews] ${FEEDS.length - failed.length}/${FEEDS.length} kaynaktan ` +
      `${unique.length} benzersiz haber alındı.`
    );

    await upsertNews(unique, failed);
    await cleanOldNews();

    console.log("[fetchNews] Tamamlandı.");
  }
);

module.exports = { fetchNews };
