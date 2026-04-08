/**
 * fetchMarketPrices — her 1 dakikada bir çalışır
 *
 * Kaynaklar:
 *   Yahoo Finance v1 (ücretsiz) : USDTRY=X, EURTRY=X, GC=F, XU100.IS + BIST hisseler + ABD hisseler
 *   Binance (ücretsiz)          : BTCTRY, ETHTRY, SOLTRY, BNBTRY, XRPTRY, AVAX, DOGE
 *   exchangerate.host (ücretsiz): USD/TRY fallback + GBP/TRY, CHF/TRY
 *
 * Firestore şeması (market/live_prices):
 * {
 *   lastFetch: Timestamp,
 *   prices: {
 *     "USDTRY=X":    { price, changePercent, lastUpdated },
 *     "EURTRY=X":    { price, changePercent, lastUpdated },
 *     "GBPTRY=X":    { price, changePercent, lastUpdated },
 *     "XAU_GRAM_TRY":{ price, changePercent, lastUpdated },
 *     "XU100":       { price, changePercent, lastUpdated },
 *     "BTC_TRY":     { price, changePercent, lastUpdated },
 *     "ETH_TRY":     { price, changePercent, lastUpdated },
 *     "SOL_TRY":     { price, changePercent, lastUpdated },
 *     "BNB_TRY":     { price, changePercent, lastUpdated },
 *     "XRP_TRY":     { price, changePercent, lastUpdated },
 *   },
 *   stocks: {
 *     "GARAN": { price, changePercent, lastUpdated, name },
 *     "BIMAS": { ... },
 *     ...
 *   },
 *   us_stocks: {
 *     "AAPL": { price, changePercent, lastUpdated, name, currency: "USD" },
 *     "TSLA": { ... },
 *     ...
 *   }
 * }
 */

const { onSchedule }              = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const axios                        = require("axios");

// ── Sabitler ─────────────────────────────────────────────────────────────────

const TROY_OZ_TO_GRAM = 31.1035;
const RATE_LIMIT_MS   = 45_000; // 45 saniyeden kısa aralıkta tekrar çalışmaz

// Yahoo endpoint'leri — sırayla dene
const YAHOO_ENDPOINTS = [
  "https://query1.finance.yahoo.com/v7/finance/quote",
  "https://query2.finance.yahoo.com/v7/finance/quote",
  "https://query1.finance.yahoo.com/v8/finance/spark",
];

// Temel döviz + emtia + BIST100
const BASE_SYMBOLS = "USDTRY=X,EURTRY=X,GBPTRY=X,CHFTRY=X,GC=F,XU100.IS";

// Popüler BIST hisse senetleri (Yahoo'da .IS suffix ile)
const BIST_SYMBOLS = [
  "GARAN.IS", "BIMAS.IS", "THYAO.IS", "AKBNK.IS", "ASELS.IS",
  "EREGL.IS", "SISE.IS",  "KCHOL.IS", "ISCTR.IS", "SAHOL.IS",
  "TCELL.IS", "ARCLK.IS", "FROTO.IS", "KOZAL.IS", "YKBNK.IS",
  "TUPRS.IS", "TOASO.IS", "PGSUS.IS", "VESTL.IS", "SOKM.IS",
];

// İnsan okunur BIST hisse isimleri
const BIST_NAMES = {
  "GARAN.IS": "Garanti BBVA",  "BIMAS.IS": "BİM Mağazalar",
  "THYAO.IS": "Türk Hava Yolları", "AKBNK.IS": "Akbank",
  "ASELS.IS": "Aselsan",       "EREGL.IS": "Ereğli Demir Çelik",
  "SISE.IS":  "Şişecam",       "KCHOL.IS": "Koç Holding",
  "ISCTR.IS": "İş Bankası C",  "SAHOL.IS": "Sabancı Holding",
  "TCELL.IS": "Turkcell",      "ARCLK.IS": "Arçelik",
  "FROTO.IS": "Ford Otomotiv", "KOZAL.IS": "Koza Altın",
  "YKBNK.IS": "Yapı Kredi",    "TUPRS.IS": "Tüpraş",
  "TOASO.IS": "Tofaş Oto",     "PGSUS.IS": "Pegasus",
  "VESTL.IS": "Vestel",        "SOKM.IS":  "Şok Marketler",
};

// Popüler ABD hisseleri
const US_SYMBOLS = [
  "AAPL", "TSLA", "NVDA", "MSFT", "AMZN",
  "META", "GOOGL", "BRK-B", "JPM", "V",
];

const US_NAMES = {
  "AAPL": "Apple", "TSLA": "Tesla", "NVDA": "Nvidia",
  "MSFT": "Microsoft", "AMZN": "Amazon", "META": "Meta",
  "GOOGL": "Google", "BRK-B": "Berkshire", "JPM": "JP Morgan",
  "V": "Visa",
};

// Binance kripto çiftleri (TRY)
const BINANCE_PAIRS_TRY  = '["BTCTRY","ETHTRY","SOLTRY","BNBTRY","XRPTRY","DOGETRY"]';

// ── Yardımcılar ───────────────────────────────────────────────────────────────

function toNum(v) {
  if (v == null) return 0;
  const n = typeof v === "number" ? v : parseFloat(v);
  return isNaN(n) ? 0 : n;
}

/** Yahoo Finance'dan toplu sembol çekimi; başarısız olursa null */
async function fetchYahoo(symbols) {
  const symbolStr = Array.isArray(symbols) ? symbols.join(",") : symbols;
  for (const base of YAHOO_ENDPOINTS.slice(0, 2)) {
    try {
      const res = await axios.get(base, {
        params:  { symbols: symbolStr },
        headers: { "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" },
        timeout: 10000,
      });
      const results = res.data?.quoteResponse?.result;
      if (results && results.length > 0) {
        const map = {};
        for (const q of results) { if (q?.symbol) map[q.symbol] = q; }
        return map;
      }
    } catch {
      // bir sonraki endpoint'e geç
    }
  }
  return null;
}

/** exchangerate.host'tan USD/TRY kuru (Yahoo fallback) */
async function fetchFallbackUsdTry() {
  try {
    const res = await axios.get("https://open.er-api.com/v6/latest/USD", { timeout: 5000 });
    const rate = toNum(res.data?.rates?.TRY);
    if (rate > 0) return rate;
  } catch { /* ignore */ }
  try {
    const res = await axios.get("https://api.exchangerate-api.com/v4/latest/USD", { timeout: 5000 });
    const rate = toNum(res.data?.rates?.TRY);
    if (rate > 0) return rate;
  } catch { /* ignore */ }
  return 0;
}

// ── Ana fonksiyon ─────────────────────────────────────────────────────────────

exports.fetchMarketPrices = onSchedule(
  {
    schedule:       "every 1 minutes",
    timeZone:       "Europe/Istanbul",
    memory:         "512MiB",
    timeoutSeconds: 60,
    region:         "europe-west1",
  },
  async () => {
    const db  = getFirestore();
    const ref = db.doc("market/live_prices");

    // ── Rate-limit guard ─────────────────────────────────────────────────────
    const snap = await ref.get();
    if (snap.exists) {
      const lastFetch = snap.data()?.lastFetch?.toDate?.();
      if (lastFetch && Date.now() - lastFetch.getTime() < RATE_LIMIT_MS) {
        console.log("[fetchMarketPrices] Rate limit — atlandı.");
        return;
      }
    }

    const nowISO = new Date().toISOString();
    const prices = {};
    const stocks    = {};
    const us_stocks = {};

    // ── 1. Yahoo Finance: Temel döviz, emtia, BIST100 ────────────────────────
    const baseMap  = await fetchYahoo(BASE_SYMBOLS);
    let usdPrice   = 0;
    let usdPrevDay = 0;

    if (baseMap) {
      const usdData = baseMap["USDTRY=X"];
      const eurData = baseMap["EURTRY=X"];
      const gbpData = baseMap["GBPTRY=X"];
      const gcData  = baseMap["GC=F"];
      const xuData  = baseMap["XU100.IS"];

      usdPrice = toNum(usdData?.regularMarketPrice);
      usdPrevDay = toNum(usdData?.regularMarketPreviousClose);

      if (usdPrice > 0) {
        prices["USDTRY=X"] = {
          price: usdPrice,
          changePercent: toNum(usdData.regularMarketChangePercent),
          lastUpdated: nowISO,
        };
      }

      const eurPrice = toNum(eurData?.regularMarketPrice);
      if (eurPrice > 0) {
        prices["EURTRY=X"] = {
          price: eurPrice,
          changePercent: toNum(eurData.regularMarketChangePercent),
          lastUpdated: nowISO,
        };
      }

      const gbpPrice = toNum(gbpData?.regularMarketPrice);
      if (gbpPrice > 0) {
        prices["GBPTRY=X"] = {
          price: gbpPrice,
          changePercent: toNum(gbpData.regularMarketChangePercent),
          lastUpdated: nowISO,
        };
      }

      const gcPrice = toNum(gcData?.regularMarketPrice);
      if (gcPrice > 0 && usdPrice > 0) {
        const gramTry = (gcPrice / TROY_OZ_TO_GRAM) * usdPrice;
        prices["XAU_GRAM_TRY"] = {
          price: Math.round(gramTry * 100) / 100,
          changePercent: toNum(gcData.regularMarketChangePercent),
          lastUpdated: nowISO,
        };
      }

      if (xuData) {
        const xuPrice = toNum(xuData.regularMarketPrice);
        const xuPrev  = toNum(xuData.regularMarketPreviousClose);
        const xuChg   = xuPrev > 0
          ? ((xuPrice - xuPrev) / xuPrev) * 100
          : toNum(xuData.regularMarketChangePercent);
        if (xuPrice > 0) {
          prices["XU100"] = {
            price: xuPrice,
            changePercent: Math.round(xuChg * 100) / 100,
            lastUpdated: nowISO,
          };
        }
      }
    } else {
      console.warn("[fetchMarketPrices] Yahoo temel döviz başarısız — fallback deneniyor…");
      usdPrice = await fetchFallbackUsdTry();
      if (usdPrice > 0) {
        prices["USDTRY=X"] = { price: usdPrice, changePercent: 0, lastUpdated: nowISO };
      }
    }

    // ── 2. Yahoo Finance: BIST Hisse Senetleri ───────────────────────────────
    const bistMap = await fetchYahoo(BIST_SYMBOLS);
    if (bistMap) {
      for (const sym of BIST_SYMBOLS) {
        const q = bistMap[sym];
        if (!q) continue;
        const price = toNum(q.regularMarketPrice);
        if (price <= 0) continue;
        const code = sym.replace(".IS", "");
        const prev = toNum(q.regularMarketPreviousClose);
        const chg  = prev > 0
          ? ((price - prev) / prev) * 100
          : toNum(q.regularMarketChangePercent);
        stocks[code] = {
          price:         Math.round(price * 100) / 100,
          changePercent: Math.round(chg * 100) / 100,
          name:          BIST_NAMES[sym] ?? code,
          currency:      "TRY",
          lastUpdated:   nowISO,
        };
      }
      console.log(`[fetchMarketPrices] BIST: ${Object.keys(stocks).length} hisse`);
    } else {
      console.warn("[fetchMarketPrices] Yahoo BIST başarısız.");
    }

    // ── 3. Yahoo Finance: ABD Hisseleri ──────────────────────────────────────
    const usMap = await fetchYahoo(US_SYMBOLS);
    if (usMap) {
      for (const sym of US_SYMBOLS) {
        const q = usMap[sym];
        if (!q) continue;
        const priceUsd = toNum(q.regularMarketPrice);
        if (priceUsd <= 0) continue;
        const prev  = toNum(q.regularMarketPreviousClose);
        const chg   = prev > 0
          ? ((priceUsd - prev) / prev) * 100
          : toNum(q.regularMarketChangePercent);
        const priceTry = usdPrice > 0 ? priceUsd * usdPrice : 0;
        us_stocks[sym] = {
          priceUsd:      Math.round(priceUsd * 100) / 100,
          priceTry:      priceTry > 0 ? Math.round(priceTry * 100) / 100 : 0,
          changePercent: Math.round(chg * 100) / 100,
          name:          US_NAMES[sym] ?? sym,
          currency:      "USD",
          lastUpdated:   nowISO,
        };
      }
      console.log(`[fetchMarketPrices] ABD: ${Object.keys(us_stocks).length} hisse`);
    } else {
      console.warn("[fetchMarketPrices] Yahoo ABD başarısız.");
    }

    // ── 4. Binance: Kripto TRY çiftleri ──────────────────────────────────────
    try {
      const bRes = await axios.get("https://api.binance.com/api/v3/ticker/24hr", {
        params:  { symbols: BINANCE_PAIRS_TRY },
        timeout: 8000,
      });
      const bList = Array.isArray(bRes.data) ? bRes.data : [];
      const bmap  = {};
      for (const item of bList) bmap[item.symbol] = item;

      const pairs = {
        "BTCTRY": "BTC_TRY", "ETHTRY": "ETH_TRY", "SOLTRY": "SOL_TRY",
        "BNBTRY": "BNB_TRY", "XRPTRY": "XRP_TRY", "DOGETRY": "DOGE_TRY",
      };
      for (const [binancePair, firestoreKey] of Object.entries(pairs)) {
        const p = toNum(bmap[binancePair]?.lastPrice);
        if (p > 0) {
          prices[firestoreKey] = {
            price:         p,
            changePercent: toNum(bmap[binancePair]?.priceChangePercent),
            lastUpdated:   nowISO,
          };
        }
      }
      console.log("[fetchMarketPrices] Binance kripto OK.");
    } catch (e) {
      console.warn("[fetchMarketPrices] Binance hatası:", e.message);
    }

    // ── 5. Firestore'a yaz ────────────────────────────────────────────────────
    const totalItems = Object.keys(prices).length + Object.keys(stocks).length + Object.keys(us_stocks).length;
    if (totalItems === 0) {
      console.error("[fetchMarketPrices] Hiçbir veri alınamadı — yazılmadı.");
      return;
    }

    const payload = { lastFetch: FieldValue.serverTimestamp() };
    if (Object.keys(prices).length > 0)    payload.prices    = prices;
    if (Object.keys(stocks).length > 0)    payload.stocks    = stocks;
    if (Object.keys(us_stocks).length > 0) payload.us_stocks = us_stocks;

    await ref.set(payload, { merge: true });
    console.log(`[fetchMarketPrices] Toplam ${totalItems} veri yazıldı.`);
  }
);
