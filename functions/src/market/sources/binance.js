/**
 * binance.js — Kripto Veri Kaynağı
 *
 * Binance public REST API'sinden TRY çiftlerini çeker.
 * Auth gerektirmez. Rate limit: 1200 req/min (bu kullanım için sorun yok).
 *
 * Endpoint: GET /api/v3/ticker/24hr?symbols=[...]
 * Döner:    lastPrice, priceChangePercent, volume
 */

"use strict";

const axios = require("axios");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const BINANCE_BASE = "https://api.binance.com";
const ENDPOINT     = "/api/v3/ticker/24hr";
const TIMEOUT_MS   = 10_000;

/**
 * Firestore key → { display sembol, isim, ikon }
 * TRY çiftleri — Binance'de direkt TRY ile işlem gören coinler
 */
const PAIR_META = {
  BTCTRY:  { key: "BTC_TRY",  symbol: "BTC/TRY",  name: "Bitcoin",  icon: "₿"  },
  ETHTRY:  { key: "ETH_TRY",  symbol: "ETH/TRY",  name: "Ethereum", icon: "⟠"  },
  SOLTRY:  { key: "SOL_TRY",  symbol: "SOL/TRY",  name: "Solana",   icon: "◎"  },
  BNBTRY:  { key: "BNB_TRY",  symbol: "BNB/TRY",  name: "BNB",      icon: "🔶" },
  XRPTRY:  { key: "XRP_TRY",  symbol: "XRP/TRY",  name: "XRP",      icon: "✕"  },
  DOGETRY: { key: "DOGE_TRY", symbol: "DOGE/TRY", name: "Dogecoin", icon: "🐕" },
  USDTTRY: { key: "USDT_TRY", symbol: "USDT/TRY", name: "Tether",   icon: "💲" },
  AVAXBTC: null, // Binance'de AVAX/TRY çifti yok — atlanır
};

const VALID_PAIRS = Object.keys(PAIR_META).filter(k => PAIR_META[k] !== null);

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round(n * 100) / 100;
const toNum  = (v) => {
  const n = parseFloat(v);
  return isNaN(n) ? 0 : n;
};

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * Kripto fiyatlarını çeker.
 *
 * @returns {{ prices: Object }} — `prices` map'ine yazılacak veriler
 * @throws  Ağ/parse hatası durumunda — fetchMarketData Promise.allSettled ile yakalar
 */
async function fetchCrypto() {
  const symbolsParam = JSON.stringify(VALID_PAIRS);

  const res = await axios.get(`${BINANCE_BASE}${ENDPOINT}`, {
    params:  { symbols: symbolsParam },
    timeout: TIMEOUT_MS,
    headers: { "Accept-Encoding": "gzip,deflate" },
  });

  if (!Array.isArray(res.data)) {
    throw new Error(`Binance unexpected response format: ${typeof res.data}`);
  }

  const now    = new Date().toISOString();
  const prices = {};

  for (const ticker of res.data) {
    const meta = PAIR_META[ticker.symbol];
    if (!meta) continue;

    const price         = toNum(ticker.lastPrice);
    const changePercent = toNum(ticker.priceChangePercent);
    const volume24h     = toNum(ticker.quoteVolume); // TRY cinsinden hacim

    if (price <= 0) {
      console.warn(`[binance] ${ticker.symbol} price is 0 — skipped`);
      continue;
    }

    prices[meta.key] = {
      price:         round2(price),
      changePercent: round2(changePercent),
      name:          meta.name,
      symbol:        meta.symbol,
      icon:          meta.icon,
      volume24h:     round2(volume24h),
      subLabel:      "kripto",
      currency:      "TRY",
      lastUpdated:   now,
    };
  }

  const count = Object.keys(prices).length;
  if (count === 0) throw new Error("Binance: no valid prices parsed");

  console.log(`[binance] ✓ ${count} kripto çekildi`);
  return { prices };
}

module.exports = { fetchCrypto };
