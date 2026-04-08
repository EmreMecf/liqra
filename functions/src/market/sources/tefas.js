/**
 * tefas.js — TEFAS Fon Verisi Kaynağı
 *
 * Resmi TEFAS API'sini kullanır (auth gerektirmez).
 * Endpoint: POST https://www.tefas.gov.tr/api/DB/BindHistoryInfo
 * Content-Type: application/x-www-form-urlencoded
 *
 * TEFAS'tan gelen ham field'lar (Türkçe, büyük harf, vb.) normalize edilir:
 *   FONKODU / FonKod / fundCode   → symbol
 *   FONUNVAN / FonUnvan / name    → name
 *   BIRIMPAYDEGERI / Fiyat        → price
 *   GUNLUK / Getiri / GunlukGetiri → changePercent
 *   AYLIK / AylikGetiri           → monthlyReturn
 *   YILLIK / YillikGetiri         → yearlyReturn
 *
 * Başarısız olursa DUMMY_FUNDS'a düşer (isDummy: true).
 *
 * Firestore şeması (market/live_prices.funds):
 * {
 *   "MAC": { symbol, name, price, changePercent, monthlyReturn, yearlyReturn,
 *            subLabel:"fon", isDummy, lastUpdated }
 * }
 */

"use strict";

const axios = require("axios");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const BASE_URL   = "https://www.tefas.gov.tr";
const ENDPOINT   = "/api/DB/BindHistoryInfo";
const TIMEOUT_MS = 20_000;

/**
 * TEFAS'ın "ben bir tarayıcıyım" sanması için zorunlu header'lar.
 * X-Requested-With olmadan 403 döner.
 */
const BROWSER_HEADERS = {
  "User-Agent":       "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Accept":           "application/json, text/javascript, */*; q=0.01",
  "X-Requested-With": "XMLHttpRequest",
  "Origin":           "https://www.tefas.gov.tr",
  "Referer":          "https://www.tefas.gov.tr/FonKarsilastirma.aspx",
  "Content-Type":     "application/x-www-form-urlencoded; charset=UTF-8",
};

// ─── Key Normalizasyon Haritası ───────────────────────────────────────────────

/**
 * TEFAS'tan gelebilecek tüm olası field isimlerini standart key'e çevirir.
 * Hem resmi API (büyük harf) hem de wrapper'ların döndürdüğü formatlar karşılanır.
 */
const KEY_MAP = {
  // Resmi TEFAS API (büyük harf)
  FONKODU:          "symbol",
  FONUNVAN:         "name",
  FONTUR:           "type",
  BIRIMPAYDEGERI:   "price",
  GUNLUK:           "changePercent",
  AYLIK:            "monthlyReturn",
  UCAYLIK:          "threeMonthReturn",
  ALTIAYLIK:        "sixMonthReturn",
  YILLIK:           "yearlyReturn",
  YILBASI:          "ytdReturn",
  TEDPAYSAYISI:     "shares",
  PORTFOYDEGERI:    "portfolioValue",
  KISISAYISI:       "investors",

  // Türkçe görünen varyantlar
  FonKod:           "symbol",
  FonUnvan:         "name",
  FonTur:           "type",
  Fiyat:            "price",
  Getiri:           "changePercent",
  GunlukGetiri:     "changePercent",
  AylikGetiri:      "monthlyReturn",
  YillikGetiri:     "yearlyReturn",

  // İngilizce wrapper varyantları (RapidAPI vb.)
  fundCode:         "symbol",
  fundName:         "name",
  fundType:         "type",
  category:         "type",
  currentPrice:     "price",
  return1d:         "changePercent",
  return1m:         "monthlyReturn",
  return3m:         "threeMonthReturn",
  return1y:         "yearlyReturn",
  returnYtd:        "ytdReturn",
};

// ─── Dummy Fallback ───────────────────────────────────────────────────────────

const DUMMY_FUNDS = [
  { symbol: "MAC", name: "Mavi Çatı Karma Fonu",          price: 2.45,  changePercent:  0.82, monthlyReturn:  2.1,  yearlyReturn: 18.4 },
  { symbol: "IPB", name: "İş Portföy BIST30 Endeks Fon",  price: 5.13,  changePercent:  1.24, monthlyReturn:  3.5,  yearlyReturn: 24.7 },
  { symbol: "TTE", name: "Tacirler Portföy Teknoloji Fon", price: 8.67,  changePercent: -0.35, monthlyReturn: -1.2,  yearlyReturn: 31.2 },
  { symbol: "GAF", name: "Garanti BBVA Portföy Hisse",     price: 3.21,  changePercent:  2.10, monthlyReturn:  4.8,  yearlyReturn: 22.9 },
  { symbol: "YAS", name: "Yapı Kredi Altın Fonu",          price: 12.90, changePercent:  0.45, monthlyReturn:  1.8,  yearlyReturn: 28.3 },
];

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((n || 0) * 100) / 100;

function toNum(v) {
  if (v == null) return 0;
  if (typeof v === "number") return isNaN(v) ? 0 : v;
  const n = parseFloat(String(v).replace(",", "."));
  return isNaN(n) ? 0 : n;
}

function fmtDate(date) {
  const d = String(date.getDate()).padStart(2, "0");
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const y = date.getFullYear();
  return `${d}.${m}.${y}`;
}

/**
 * Ham TEFAS objesini standart formata normalize eder.
 * KEY_MAP'te karşılığı olmayan field'lar da (camelCase veya snake_case)
 * direkt alınır — böylece yeni field'lar sessizce geçer.
 */
function normalizeItem(raw) {
  const out = {};

  for (const [rawKey, rawVal] of Object.entries(raw)) {
    const mappedKey = KEY_MAP[rawKey];
    if (mappedKey) {
      // Zaten bir değer varsa ilkini koru (aynı target'a iki kaynak map'lenebilir)
      if (!(mappedKey in out)) {
        out[mappedKey] = rawVal;
      }
    }
    // Bilinmeyen key'leri de tut (veri kaybı olmasın)
  }

  return out;
}

/**
 * Normalize edilmiş objeyi Firestore'a yazılacak standart formata dönüştürür.
 */
function toFirestoreEntry(normalized, now) {
  const symbol = String(normalized.symbol ?? "").toUpperCase().trim();
  if (!symbol) return null;

  return {
    symbol,
    name:           String(normalized.name ?? symbol),
    price:          round2(toNum(normalized.price)),
    changePercent:  round2(toNum(normalized.changePercent)),
    monthlyReturn:  round2(toNum(normalized.monthlyReturn)),
    yearlyReturn:   round2(toNum(normalized.yearlyReturn)),
    subLabel:       "fon",
    isDummy:        false,
    lastUpdated:    now,
  };
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * TEFAS fon verilerini çeker ve normalize eder.
 * Başarısız olursa dummy veriye düşer.
 *
 * @returns {{ [code: string]: Object }}
 */
async function fetchFunds() {
  const now     = new Date().toISOString();
  const today   = fmtDate(new Date());
  const yesterday = fmtDate(new Date(Date.now() - 86_400_000));

  try {
    const params = new URLSearchParams({
      fontip:   "YAT",
      bastarih: yesterday,
      bittarih: today,
    });

    const res = await axios.post(`${BASE_URL}${ENDPOINT}`, params.toString(), {
      headers: BROWSER_HEADERS,
      timeout: TIMEOUT_MS,
    });

    // TEFAS genellikle { data: [...] } veya direkt array döner
    let items = [];
    if (Array.isArray(res.data)) {
      items = res.data;
    } else if (res.data?.data && Array.isArray(res.data.data)) {
      items = res.data.data;
    } else if (res.data?.result && Array.isArray(res.data.result)) {
      items = res.data.result;
    }

    if (items.length === 0) {
      console.warn("[tefas] API başarılı ama boş liste döndü — dummy'e düşülüyor.");
      return _buildDummy(now);
    }

    const funds = {};
    for (const raw of items) {
      const normalized = normalizeItem(raw);
      const entry      = toFirestoreEntry(normalized, now);
      if (!entry || entry.price <= 0) continue;
      funds[entry.symbol] = entry;
    }

    const count = Object.keys(funds).length;
    if (count === 0) {
      console.warn("[tefas] Parse sonucu boş — dummy'e düşülüyor.");
      return _buildDummy(now);
    }

    console.log(`[tefas] ✓ ${count} fon normalize edildi`);
    return funds;

  } catch (err) {
    console.error("[tefas] ✗ API hatası:", err.response?.status ?? err.message);
    return _buildDummy(now);
  }
}

function _buildDummy(now) {
  const funds = {};
  for (const f of DUMMY_FUNDS) {
    funds[f.symbol] = {
      symbol:        f.symbol,
      name:          f.name,
      price:         f.price,
      changePercent: f.changePercent,
      monthlyReturn: f.monthlyReturn,
      yearlyReturn:  f.yearlyReturn,
      subLabel:      "fon",
      isDummy:       true,
      lastUpdated:   now,
    };
  }
  console.log(`[tefas] ℹ️  Dummy data — ${DUMMY_FUNDS.length} fon`);
  return funds;
}

module.exports = { fetchFunds };
