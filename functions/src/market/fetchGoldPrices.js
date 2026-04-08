/**
 * fetchGoldPrices — her 5 dakikada bir çalışır
 *
 * Kaynak: finans.truncgil.com/v4/today.json (ücretsiz, auth yok)
 * Yedek:  YahooFinance GC=F + USD/TRY hesabı
 *
 * Yazar: market/live_prices dokümanına "gold" haritasını ekler:
 * {
 *   gold: {
 *     gram:        { alis, satis, degisim, degisimTutar },
 *     ceyrek:      { alis, satis, degisim, degisimTutar },
 *     yarim:       { alis, satis, degisim, degisimTutar },
 *     tam:         { alis, satis, degisim, degisimTutar },
 *     cumhuriyet:  { alis, satis, degisim, degisimTutar },
 *     resat:       { alis, satis, degisim, degisimTutar },
 *     beslilik:    { alis, satis, degisim, degisimTutar },
 *     hamit:       { alis, satis, degisim, degisimTutar },
 *     bilezik22:   { alisgram, satisgram, degisim },
 *     bilezik18:   { alisgram, satisgram, degisim },
 *     bilezik14:   { alisgram, satisgram, degisim },
 *     gumus:       { alis, satis, degisim },
 *     lastUpdated: ISO string
 *   }
 * }
 */

const { onSchedule }              = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const axios                        = require("axios");

const TRUNCGIL_URL = "https://finans.truncgil.com/v4/today.json";
const RATE_LIMIT_GOLD_MS = 4 * 60_000; // 4 dakika

// Truncgil anahtar → Firestore anahtar
const KEY_MAP = {
  "Gram Altın":         "gram",
  "Çeyrek Altın":       "ceyrek",
  "Yarım Altın":        "yarim",
  "Tam Altın":          "tam",
  "Cumhuriyet Altını":  "cumhuriyet",
  "Reşat Altın":        "resat",
  "Beşlilik":           "beslilik",
  "Hamit Altın":        "hamit",
  "22 Ayar Bilezik":    "bilezik22",
  "18 Ayar Bilezik":    "bilezik18",
  "14 Ayar Bilezik":    "bilezik14",
  "Gümüş":              "gumus",
};

// Bilezik kayıtlarında fiyat adet değil gram başı fiyat
const BILEZIK_KEYS = new Set(["bilezik22", "bilezik18", "bilezik14"]);

function parseNum(str) {
  if (str == null) return 0;
  if (typeof str === "number") return isNaN(str) ? 0 : str;
  // "4.100,50" veya "4100,50" veya "4100.50" formatlarını destekle
  const cleaned = str.toString()
    .replace(/\./g, "")   // binlik ayırıcı noktaları kaldır
    .replace(",", ".");    // ondalık virgülü noktaya çevir
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

function parseDegisim(str) {
  if (str == null) return 0;
  // "%0,50" veya "%-0,50" formatı
  const cleaned = str.toString()
    .replace("%", "")
    .replace(",", ".")
    .trim();
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

async function fetchTruncgil() {
  try {
    const res = await axios.get(TRUNCGIL_URL, {
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; LiqraApp/1.0)",
        "Accept":     "application/json",
      },
      timeout: 10000,
    });
    if (res.data && typeof res.data === "object") return res.data;
    return null;
  } catch (e) {
    console.warn("[fetchGoldPrices] Truncgil hatası:", e.message);
    return null;
  }
}

/** Yahoo Finance + USD/TRY ile gram altın hesapla (yedek) */
async function fetchGoldFromYahoo() {
  try {
    const res = await axios.get("https://query1.finance.yahoo.com/v7/finance/quote", {
      params:  { symbols: "GC=F,USDTRY=X" },
      headers: { "User-Agent": "Mozilla/5.0" },
      timeout: 8000,
    });
    const results = res.data?.quoteResponse?.result ?? [];
    const map = {};
    for (const q of results) { if (q?.symbol) map[q.symbol] = q; }

    const usdTry = map["USDTRY=X"]?.regularMarketPrice ?? 0;
    const gcUsd  = map["GC=F"]?.regularMarketPrice ?? 0;
    const gcChg  = map["GC=F"]?.regularMarketChangePercent ?? 0;

    if (usdTry <= 0 || gcUsd <= 0) return null;

    const TROY_OZ = 31.1035;
    const gramTry = (gcUsd / TROY_OZ) * usdTry;
    const spread  = gramTry * 0.004; // yaklaşık %0.4 spread

    return {
      gram: {
        alis:          Math.round((gramTry - spread) * 100) / 100,
        satis:         Math.round((gramTry + spread) * 100) / 100,
        degisim:       Math.round(gcChg * 100) / 100,
        degisimTutar:  Math.round(gramTry * gcChg / 100 * 100) / 100,
      },
    };
  } catch {
    return null;
  }
}

/** Gram altın fiyatından diğer türleri hesapla */
function deriveFromGram(gramAlis, gramSatis, gramDegisim) {
  const WEIGHTS = {
    ceyrek:     { g: 1.75,  spread: 0.015 },
    yarim:      { g: 3.50,  spread: 0.012 },
    tam:        { g: 7.00,  spread: 0.010 },
    cumhuriyet: { g: 7.00,  spread: 0.010 },
    resat:      { g: 7.30,  spread: 0.012 },
    beslilik:   { g: 35.00, spread: 0.008 },
    hamit:      { g: 7.30,  spread: 0.012 },
  };
  const result = {};
  for (const [key, cfg] of Object.entries(WEIGHTS)) {
    const mid    = ((gramAlis + gramSatis) / 2) * cfg.g;
    const sp     = mid * cfg.spread;
    result[key]  = {
      alis:         Math.round((mid - sp) * 100) / 100,
      satis:        Math.round((mid + sp) * 100) / 100,
      degisim:      gramDegisim,
      degisimTutar: Math.round(mid * gramDegisim / 100 * 100) / 100,
    };
  }

  // Bilezikler: ayarlı gram fiyatı
  const AYAR = { bilezik22: 22/24, bilezik18: 18/24, bilezik14: 14/24 };
  const gramMid = (gramAlis + gramSatis) / 2;
  for (const [key, ratio] of Object.entries(AYAR)) {
    const gramPrice = gramMid * ratio;
    const sp = gramPrice * 0.02;
    result[key] = {
      alisgram:  Math.round((gramPrice - sp) * 100) / 100,
      satisgram: Math.round((gramPrice + sp) * 100) / 100,
      degisim:   gramDegisim,
    };
  }
  return result;
}

// ── Ana Fonksiyon ─────────────────────────────────────────────────────────────

exports.fetchGoldPrices = onSchedule(
  {
    schedule:       "every 5 minutes",
    timeZone:       "Europe/Istanbul",
    memory:         "256MiB",
    timeoutSeconds: 30,
    region:         "europe-west1",
  },
  async () => {
    const db  = getFirestore();
    const ref = db.doc("market/live_prices");

    // Rate limit
    const snap = await ref.get();
    const goldLastFetch = snap.data()?.goldLastFetch?.toDate?.();
    if (goldLastFetch && Date.now() - goldLastFetch.getTime() < RATE_LIMIT_GOLD_MS) {
      console.log("[fetchGoldPrices] Rate limit — atlandı.");
      return;
    }

    const nowISO = new Date().toISOString();
    const gold   = {};

    // ── 1. Truncgil API ────────────────────────────────────────────────────
    const raw = await fetchTruncgil();
    if (raw) {
      for (const [turkishKey, fsKey] of Object.entries(KEY_MAP)) {
        const item = raw[turkishKey];
        if (!item) continue;

        const alis   = parseNum(item["Alış"] ?? item["Alis"]);
        const satis  = parseNum(item["Satış"] ?? item["Satis"]);
        const degStr = item["Değişim"] ?? item["Degisim"] ?? "0";
        const degisim = parseDegisim(degStr);

        if (alis <= 0 && satis <= 0) continue;

        if (BILEZIK_KEYS.has(fsKey)) {
          // Bilezik: gram başı fiyat
          gold[fsKey] = {
            alisgram:   alis > 0 ? alis : satis,
            satisgram:  satis > 0 ? satis : alis,
            degisim:    Math.round(degisim * 100) / 100,
          };
        } else {
          const mid        = (alis + satis) / 2;
          const degTutar   = Math.round(mid * degisim / 100 * 100) / 100;
          gold[fsKey] = {
            alis:         alis > 0 ? alis : satis,
            satis:        satis > 0 ? satis : alis,
            degisim:      Math.round(degisim * 100) / 100,
            degisimTutar: degTutar,
          };
        }
      }
      console.log(`[fetchGoldPrices] Truncgil: ${Object.keys(gold).length} kayıt`);
    }

    // ── 2. Yedek: Yahoo Finance ────────────────────────────────────────────
    if (!gold.gram) {
      console.warn("[fetchGoldPrices] Truncgil gram altın yok — Yahoo fallback…");
      const yahooGold = await fetchGoldFromYahoo();
      if (yahooGold?.gram) {
        gold.gram = yahooGold.gram;
      }
    }

    // ── 3. Türev hesapla (eksik anahtar varsa) ────────────────────────────
    if (gold.gram) {
      const { alis, satis, degisim } = gold.gram;
      const derived = deriveFromGram(alis, satis, degisim);
      for (const [k, v] of Object.entries(derived)) {
        if (!gold[k]) gold[k] = v; // sadece eksikleri doldur
      }
    }

    // ── 4. Firestore'a yaz ────────────────────────────────────────────────
    if (Object.keys(gold).length === 0) {
      console.error("[fetchGoldPrices] Hiçbir altın verisi alınamadı.");
      return;
    }

    gold.lastUpdated = nowISO;

    await ref.set(
      { gold, goldLastFetch: FieldValue.serverTimestamp() },
      { merge: true },
    );

    console.log(`[fetchGoldPrices] ${Object.keys(gold).length} altın türü yazıldı.`);
  }
);
