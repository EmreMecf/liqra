/**
 * yahoo.js — Hisse Senedi Veri Kaynağı (BIST + ABD)
 *
 * yahoo-finance2 npm paketi kullanır. Tek HTTP isteğiyle toplu (batch) çekim yapar.
 * BIST için Yahoo'nun .IS suffix'i, ABD için direkt sembol kullanılır.
 *
 * Döner: { bist: Object, us: Object, usdTry: number }
 * usdTry → CollectAPI başarısız olursa prices map'teki USDTRY için fallback
 */

"use strict";

// yahoo-finance2 ESM-only paket — CJS ortamında dynamic import() ile yüklenir
// Node.js 14+ ve Cloud Functions v2 destekler
let _yahooFinance = null;
async function getYahooFinance() {
  if (!_yahooFinance) {
    const mod = await import("yahoo-finance2");
    _yahooFinance = mod.default;
    try { _yahooFinance.suppressNotices(["yahooSurvey", "ripHistoricalDividends"]); } catch (_) {}
  }
  return _yahooFinance;
}

// ─── Sembol Listeleri ─────────────────────────────────────────────────────────

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

// BIST100 endeksi + USD/TRY — fallback için de alınır
const EXTRA_SYMBOLS = ["XU100.IS", "USDTRY=X"];

const BIST_META = {
  "GARAN.IS": { name: "Garanti BBVA",        icon: "🏦" },
  "BIMAS.IS": { name: "BİM Mağazalar",        icon: "🛒" },
  "THYAO.IS": { name: "Türk Hava Yolları",    icon: "✈️" },
  "AKBNK.IS": { name: "Akbank",               icon: "🏦" },
  "ASELS.IS": { name: "Aselsan",              icon: "🛡️" },
  "EREGL.IS": { name: "Ereğli Demir Çelik",  icon: "⚙️" },
  "SISE.IS":  { name: "Şişecam",              icon: "🔬" },
  "KCHOL.IS": { name: "Koç Holding",          icon: "🏭" },
  "ISCTR.IS": { name: "İş Bankası C",         icon: "🏦" },
  "SAHOL.IS": { name: "Sabancı Holding",      icon: "🏢" },
  "TCELL.IS": { name: "Turkcell",             icon: "📱" },
  "ARCLK.IS": { name: "Arçelik",              icon: "🏠" },
  "FROTO.IS": { name: "Ford Otomotiv",        icon: "🚗" },
  "KOZAL.IS": { name: "Koza Altın",           icon: "🥇" },
  "YKBNK.IS": { name: "Yapı Kredi",           icon: "🏦" },
  "TUPRS.IS": { name: "Tüpraş",              icon: "⛽" },
  "TOASO.IS": { name: "Tofaş Oto",           icon: "🚙" },
  "PGSUS.IS": { name: "Pegasus",              icon: "✈️" },
  "VESTL.IS": { name: "Vestel",              icon: "📺" },
  "SOKM.IS":  { name: "Şok Marketler",        icon: "🛍️" },
};

const US_META = {
  "AAPL":  { name: "Apple",      icon: "🍎" },
  "TSLA":  { name: "Tesla",      icon: "⚡" },
  "NVDA":  { name: "Nvidia",     icon: "🟢" },
  "MSFT":  { name: "Microsoft",  icon: "🪟" },
  "AMZN":  { name: "Amazon",     icon: "📦" },
  "META":  { name: "Meta",       icon: "👓" },
  "GOOGL": { name: "Google",     icon: "🔍" },
  "BRK-B": { name: "Berkshire",  icon: "💼" },
  "JPM":   { name: "JP Morgan",  icon: "🏦" },
  "V":     { name: "Visa",       icon: "💳" },
};

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((n || 0) * 100) / 100;

function changePercent(price, prevClose, fallback = 0) {
  if (price > 0 && prevClose > 0) {
    return round2(((price - prevClose) / prevClose) * 100);
  }
  return round2(fallback);
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * BIST ve ABD hisse senetlerini + XU100 endeksini tek sorguda çeker.
 *
 * @param {number} usdTryFallback  CollectAPI'den gelen USD/TRY kuru
 *                                 (ABD hisselerini TRY'ye çevirmek için)
 * @returns {{ bist, us, xu100, usdTryFromYahoo }}
 */
async function fetchStocks(usdTryFallback = 0) {
  const yahooFinance = await getYahooFinance();
  const allSymbols   = [...BIST_SYMBOLS, ...US_SYMBOLS, ...EXTRA_SYMBOLS];
  const now          = new Date().toISOString();

  // yahoo-finance2: dizi verildiğinde tek HTTP isteğiyle toplu çekim
  // validateResult: false → strict schema hatalarında crash etme
  const rawQuotes = await yahooFinance.quote(allSymbols, {}, { validateResult: false });

  // Tek sembol verilince obje, dizi verilince dizi döner — normalize et
  const quotes = Array.isArray(rawQuotes) ? rawQuotes : [rawQuotes];

  const bist  = {};
  const us    = {};
  let   xu100 = null;
  let   usdTryFromYahoo = 0;

  for (const q of quotes) {
    if (!q?.symbol) continue;

    const sym   = q.symbol;
    const price = q.regularMarketPrice ?? 0;
    const prev  = q.regularMarketPreviousClose ?? 0;
    const chg   = changePercent(price, prev, q.regularMarketChangePercent ?? 0);

    // ── BIST100 Endeksi ────────────────────────────────────────────────────
    if (sym === "XU100.IS") {
      if (price > 0) {
        xu100 = { price: round2(price), changePercent: chg };
      }
      continue;
    }

    // ── USD/TRY Fallback ───────────────────────────────────────────────────
    if (sym === "USDTRY=X") {
      usdTryFromYahoo = price;
      continue;
    }

    // ── BIST Hissesi ────────────────────────────────────────────────────
    if (sym.endsWith(".IS")) {
      if (price <= 0) {
        console.warn(`[yahoo] BIST ${sym} price=0 — skipped`);
        continue;
      }
      const code = sym.replace(".IS", "");
      const meta = BIST_META[sym] ?? { name: code, icon: "📈" };

      bist[code] = {
        price:         round2(price),
        changePercent: chg,
        name:          meta.name,
        icon:          meta.icon,
        symbol:        code,
        currency:      "TRY",
        subLabel:      "bist",
        lastUpdated:   now,
      };
      continue;
    }

    // ── ABD Hissesi ─────────────────────────────────────────────────────
    if (US_META[sym]) {
      if (price <= 0) {
        console.warn(`[yahoo] US ${sym} price=0 — skipped`);
        continue;
      }
      const meta     = US_META[sym];
      const usdTry   = usdTryFallback || usdTryFromYahoo;
      const priceTry = usdTry > 0 ? round2(price * usdTry) : 0;

      us[sym] = {
        priceUsd:      round2(price),
        priceTry,
        changePercent: chg,
        name:          meta.name,
        icon:          meta.icon,
        symbol:        sym,
        currency:      "USD",
        subLabel:      "abd",
        lastUpdated:   now,
      };
    }
  }

  const bistCount = Object.keys(bist).length;
  const usCount   = Object.keys(us).length;

  if (bistCount === 0 && usCount === 0) {
    throw new Error("Yahoo: no stocks parsed from response");
  }

  console.log(`[yahoo] ✓ BIST: ${bistCount}  ABD: ${usCount}  XU100: ${xu100 ? "✓" : "✗"}`);

  return { bist, us, xu100, usdTryFromYahoo };
}

module.exports = { fetchStocks };
