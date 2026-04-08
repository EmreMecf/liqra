/**
 * yahoo.js — Hisse Senedi Veri Kaynağı (BIST + ABD)
 *
 * Mimari:
 *   1. Tüm sembolleri tek batch isteğiyle çekmeyi dener (hızlı).
 *   2. Batch başarısız olursa her sembol için ayrı ayrı try-catch ile dener
 *      (yavaş ama fault-tolerant — tek hatalı sembol diğerlerini kesmez).
 *   3. Her iki yöntem de parse aşamasında sembol başına try-catch uygular.
 *   4. Sonuçları Firestore market/live_prices dökümanına { merge: true } ile yazar.
 *      merge:true → stocks/us_stocks dışındaki map'ler (prices, gold, funds) korunur.
 *
 * Döner: { bist, us, xu100, usdTryFromYahoo }
 *   xu100 + usdTryFromYahoo → fetchMarketData.js tarafından prices map'ine eklenir.
 *
 * Flutter key sözleşmesi:
 *   price          → double  (TRY veya USD)
 *   changePercent  → double  (yüzde, örn: -1.23 = %-1.23)
 *   priceUsd       → double  (sadece ABD hisseleri)
 *   priceTry       → double  (sadece ABD hisseleri, 0 ise USD/TRY kuru yoktu)
 *   subLabel       → String  "bist" | "abd"
 */

"use strict";

const { getFirestore } = require("firebase-admin/firestore");

// ─── ESM Yükleme ──────────────────────────────────────────────────────────────
// yahoo-finance2 ESM-only — CJS ortamında dynamic import() zorunlu

let _yf = null;
async function _getYf() {
  if (!_yf) {
    const mod = await import("yahoo-finance2");
    _yf = mod.default;
    try { _yf.suppressNotices(["yahooSurvey", "ripHistoricalDividends"]); } catch (_) {}
  }
  return _yf;
}

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const FIRESTORE_DOC = "market/live_prices";

const BIST_SYMBOLS = [
  "GARAN.IS", "BIMAS.IS", "THYAO.IS", "AKBNK.IS", "ASELS.IS",
  "EREGL.IS", "SISE.IS",  "KCHOL.IS", "ISCTR.IS", "SAHOL.IS",
  "TCELL.IS", "ARCLK.IS", "FROTO.IS", "KOZAL.IS", "YKBNK.IS",
  "TUPRS.IS", "TOASO.IS", "PGSUS.IS", "VESTL.IS", "SOKM.IS",
];

const US_SYMBOLS = [
  "AAPL", "TSLA", "NVDA", "MSFT", "AMZN",
  "META", "GOOGL", "BRK-B", "JPM", "V",
];

const EXTRA_SYMBOLS = ["XU100.IS", "USDTRY=X"];

const ALL_SYMBOLS = [...BIST_SYMBOLS, ...US_SYMBOLS, ...EXTRA_SYMBOLS];

// Sembol → { name, icon } — Yahoo'nun döndürdüğü isim çoğunlukla İngilizce/kısaltma
const BIST_META = {
  "GARAN.IS": { name: "Garanti BBVA",       icon: "🏦" },
  "BIMAS.IS": { name: "BİM Mağazalar",       icon: "🛒" },
  "THYAO.IS": { name: "Türk Hava Yolları",   icon: "✈️"  },
  "AKBNK.IS": { name: "Akbank",              icon: "🏦" },
  "ASELS.IS": { name: "Aselsan",             icon: "🛡️"  },
  "EREGL.IS": { name: "Ereğli Demir Çelik", icon: "⚙️"  },
  "SISE.IS":  { name: "Şişecam",             icon: "🔬" },
  "KCHOL.IS": { name: "Koç Holding",         icon: "🏭" },
  "ISCTR.IS": { name: "İş Bankası C",        icon: "🏦" },
  "SAHOL.IS": { name: "Sabancı Holding",     icon: "🏢" },
  "TCELL.IS": { name: "Turkcell",            icon: "📱" },
  "ARCLK.IS": { name: "Arçelik",             icon: "🏠" },
  "FROTO.IS": { name: "Ford Otomotiv",       icon: "🚗" },
  "KOZAL.IS": { name: "Koza Altın",          icon: "🥇" },
  "YKBNK.IS": { name: "Yapı Kredi",          icon: "🏦" },
  "TUPRS.IS": { name: "Tüpraş",             icon: "⛽" },
  "TOASO.IS": { name: "Tofaş Oto",          icon: "🚙" },
  "PGSUS.IS": { name: "Pegasus",             icon: "✈️"  },
  "VESTL.IS": { name: "Vestel",             icon: "📺" },
  "SOKM.IS":  { name: "Şok Marketler",       icon: "🛍️"  },
};

const US_META = {
  "AAPL":  { name: "Apple",     icon: "🍎" },
  "TSLA":  { name: "Tesla",     icon: "⚡" },
  "NVDA":  { name: "Nvidia",    icon: "🟢" },
  "MSFT":  { name: "Microsoft", icon: "🪟" },
  "AMZN":  { name: "Amazon",    icon: "📦" },
  "META":  { name: "Meta",      icon: "👓" },
  "GOOGL": { name: "Google",    icon: "🔍" },
  "BRK-B": { name: "Berkshire", icon: "💼" },
  "JPM":   { name: "JP Morgan", icon: "🏦" },
  "V":     { name: "Visa",      icon: "💳" },
};

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((isNaN(n) || n == null ? 0 : n) * 100) / 100;

/**
 * Yüzde değişim hesaplar.
 * Yahoo bazen regularMarketChangePercent'i düzgün vermez — elle hesaplarız.
 */
function calcChangePercent(price, prevClose, fallback = 0) {
  if (price > 0 && prevClose > 0) {
    return round2(((price - prevClose) / prevClose) * 100);
  }
  return round2(fallback);
}

/**
 * Tek bir ham Yahoo quote objesini parse eder.
 * Hata atarsa çağıran catch'ler — sistem çökmez.
 *
 * @returns {{ type: "bist"|"us"|"xu100"|"usdtry"|"skip", ... }}
 */
function parseQuote(q, usdTry, now) {
  const sym   = q?.symbol;
  if (!sym) return { type: "skip" };

  const price = q.regularMarketPrice          ?? 0;
  const prev  = q.regularMarketPreviousClose  ?? 0;
  const chgPct = calcChangePercent(
    price, prev,
    q.regularMarketChangePercent ?? 0,
  );

  // XU100 endeksi
  if (sym === "XU100.IS") {
    if (price <= 0) return { type: "skip" };
    return { type: "xu100", price: round2(price), changePercent: chgPct };
  }

  // USD/TRY fallback
  if (sym === "USDTRY=X") {
    return { type: "usdtry", rate: price };
  }

  // BIST hissesi
  if (sym.endsWith(".IS")) {
    if (price <= 0) {
      console.warn(`[yahoo] BIST ${sym} price=0 — atlandı`);
      return { type: "skip" };
    }
    const code = sym.replace(".IS", "");
    const meta = BIST_META[sym] ?? { name: code, icon: "📈" };
    return {
      type:  "bist",
      key:   code,
      entry: {
        price:         round2(price),
        changePercent: chgPct,
        name:          meta.name,
        icon:          meta.icon,
        symbol:        code,
        currency:      "TRY",
        subLabel:      "bist",       // Flutter bu değerle filtreler
        lastUpdated:   now,
      },
    };
  }

  // ABD hissesi
  if (US_META[sym]) {
    if (price <= 0) {
      console.warn(`[yahoo] ABD ${sym} price=0 — atlandı`);
      return { type: "skip" };
    }
    const meta     = US_META[sym];
    const priceTry = usdTry > 0 ? round2(price * usdTry) : 0;
    return {
      type:  "us",
      key:   sym,
      entry: {
        priceUsd:      round2(price),
        priceTry,
        changePercent: chgPct,
        name:          meta.name,
        icon:          meta.icon,
        symbol:        sym,
        currency:      "USD",
        subLabel:      "abd",        // Flutter bu değerle filtreler
        lastUpdated:   now,
      },
    };
  }

  return { type: "skip" };
}

// ─── Çekim Stratejileri ───────────────────────────────────────────────────────

/**
 * Strateji 1: Tüm sembolleri tek batch isteğiyle çeker.
 * Başarısızsa null döner → strateji 2 devreye girer.
 */
async function _batchFetch(yf) {
  try {
    const raw = await yf.quote(ALL_SYMBOLS, {}, { validateResult: false });
    const quotes = Array.isArray(raw) ? raw : [raw];
    console.log(`[yahoo] Batch fetch OK — ${quotes.length} sembol`);
    return quotes;
  } catch (err) {
    console.warn(`[yahoo] Batch fetch başarısız: ${err.message}`);
    return null;
  }
}

/**
 * Strateji 2: Her sembol için ayrı istek + ayrı try-catch.
 * Bir sembol başarısız olsa bile diğerleri devam eder.
 */
async function _perSymbolFetch(yf) {
  console.log(`[yahoo] Per-symbol fetch başlatılıyor (${ALL_SYMBOLS.length} sembol)…`);

  const settled = await Promise.allSettled(
    ALL_SYMBOLS.map((sym) =>
      yf.quote(sym, {}, { validateResult: false })
        .then((r) => (Array.isArray(r) ? r[0] : r))
    )
  );

  const quotes = [];
  let failCount = 0;

  for (let i = 0; i < settled.length; i++) {
    const result = settled[i];
    if (result.status === "fulfilled" && result.value?.symbol) {
      quotes.push(result.value);
    } else {
      failCount++;
      console.warn(
        `[yahoo] ${ALL_SYMBOLS[i]} atlandı: ${result.reason?.message ?? "bilinmeyen hata"}`
      );
    }
  }

  console.log(`[yahoo] Per-symbol fetch tamamlandı — ${quotes.length} OK, ${failCount} hata`);
  return quotes;
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * BIST ve ABD hisselerini + XU100'ü çeker, Firestore'a yazar.
 *
 * @param {number} usdTryFallback  CollectAPI'den gelen USD/TRY kuru.
 *                                 Önce bu kullanılır; yoksa Yahoo'nun kendi kuru.
 * @returns {{ bist, us, xu100, usdTryFromYahoo }}
 */
async function fetchStocks(usdTryFallback = 0) {
  const yf  = await _getYf();
  const now = new Date().toISOString();

  // ── 1. Veri çekimi ───────────────────────────────────────────────────────
  let quotes = await _batchFetch(yf);
  if (!quotes || quotes.length === 0) {
    quotes = await _perSymbolFetch(yf);
  }

  // ── 2. Parse (her sembol için ayrı try-catch) ────────────────────────────
  const bist = {};
  const us   = {};
  let xu100            = null;
  let usdTryFromYahoo  = 0;

  // USD/TRY önce tespit et — ABD hisselerini TRY'ye çevirmek için gerekli
  for (const q of quotes) {
    try {
      if (q?.symbol === "USDTRY=X") {
        usdTryFromYahoo = q.regularMarketPrice ?? 0;
        break;
      }
    } catch (_) {}
  }

  const usdTry = usdTryFallback || usdTryFromYahoo;

  for (const q of quotes) {
    try {
      const parsed = parseQuote(q, usdTry, now);

      switch (parsed.type) {
        case "bist":   bist[parsed.key]  = parsed.entry; break;
        case "us":     us[parsed.key]    = parsed.entry; break;
        case "xu100":  xu100             = parsed;        break;
        case "usdtry": /* zaten yukarıda aldık */         break;
        default:       /* skip */                         break;
      }
    } catch (parseErr) {
      console.warn(`[yahoo] Parse hatası (${q?.symbol}): ${parseErr.message}`);
    }
  }

  const bistCount = Object.keys(bist).length;
  const usCount   = Object.keys(us).length;

  if (bistCount === 0 && usCount === 0) {
    throw new Error("Yahoo: hiçbir hisse parse edilemedi");
  }

  // ── 3. Firestore'a yaz — merge:true ─────────────────────────────────────
  //
  // set(..., { merge: true }) davranışı:
  //   - Döküman yoksa oluşturur.
  //   - Döküman varsa sadece verilen TOP-LEVEL key'leri günceller.
  //   - prices, gold, funds map'leri bu yazımdan ETKİLENMEZ.
  //   - stocks ve us_stocks map'leri TAMAMEN YENİ VERİYLE DEĞİŞİR.
  //     (Başarısız olan semboller için eski veri silinir — bilerek tercih edildi.
  //      Eski veri kalsın istersen update() + dot-notation kullan.)

  const firestorePayload = {};
  if (bistCount > 0) firestorePayload.stocks    = bist;
  if (usCount   > 0) firestorePayload.us_stocks = us;

  if (Object.keys(firestorePayload).length > 0) {
    const ref = getFirestore().doc(FIRESTORE_DOC);
    await ref.set(firestorePayload, { merge: true });
    console.log(
      `[yahoo] ✓ Firestore yazıldı — BIST: ${bistCount}  ABD: ${usCount}  XU100: ${xu100 ? "✓" : "✗"}`
    );
  }

  return { bist, us, xu100, usdTryFromYahoo };
}

module.exports = { fetchStocks };
