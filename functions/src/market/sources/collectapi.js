/**
 * collectapi.js — Döviz & Altın Veri Kaynağı
 *
 * CollectAPI Economy API kullanır.
 * Döküman: https://collectapi.com/api/economy/
 *
 * API Key → Firebase Secret Manager: "COLLECT_API_KEY"
 * Header:  Authorization: apikey <KEY>
 *
 * Endpointler:
 *   /economy/goldPrice      → Türk altın türleri (Gram, Çeyrek, Tam, Cumhuriyet...)
 *   /economy/allCurrency    → Döviz kurları (USD, EUR, GBP, CHF vs.)
 *
 * Döner: { forex: Object, gold: Object, usdTry: number }
 * usdTry → Yahoo'daki ABD hisselerini TRY'ye çevirmek için paylaşılır
 */

"use strict";

const axios = require("axios");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const BASE_URL   = "https://api.collectapi.com";
const TIMEOUT_MS = 12_000;

// Hangi döviz kodlarını alacağız (CollectAPI döndürdüğü "code" değerleri)
const WANTED_CURRENCIES = new Set(["USD", "EUR", "GBP", "CHF"]);

// Altın isim eşleştirmesi: CollectAPI ismi → Firestore key
const GOLD_KEY_MAP = {
  "Gram Altın":        "gram",
  "Çeyrek Altın":      "ceyrek",
  "Yarım Altın":       "yarim",
  "Tam Altın":         "tam",
  "Cumhuriyet Altını": "cumhuriyet",
  "Reşat Altın":       "resat",
  "Beşlilik":          "beslilik",
  "Hamit Altın":       "hamit",
  "22 Ayar Bilezik":   "bilezik22",
  "18 Ayar Bilezik":   "bilezik18",
  "14 Ayar Bilezik":   "bilezik14",
  "Ons Altın":         "ons",
  "Gümüş":             "gumus",
};

const BILEZIK_KEYS = new Set(["bilezik22", "bilezik18", "bilezik14"]);

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((n || 0) * 100) / 100;

/**
 * "4.100,50" | "4100,50" | "4100.50" → 4100.50
 * CollectAPI Türkçe format kullanır.
 */
function parsePrice(str) {
  if (str == null)          return 0;
  if (typeof str === "number") return isNaN(str) ? 0 : str;
  const cleaned = String(str)
    .replace(/\./g, "")   // binlik ayırıcı noktaları kaldır
    .replace(",", ".");    // ondalık virgülü noktaya çevir
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

/**
 * "% 0,50" | "%-0,50" | "0.50" → 0.50
 */
function parsePct(str) {
  if (str == null) return 0;
  const cleaned = String(str)
    .replace(/[%\s]/g, "")
    .replace(",", ".");
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

function buildHeaders(apiKey) {
  return {
    "Authorization": `apikey ${apiKey}`,
    "content-type":  "application/json",
  };
}

// ─── Alt Çekiciler ────────────────────────────────────────────────────────────

/** Döviz kurlarını çeker → prices map'ine girecek format */
async function _fetchForex(apiKey) {
  const res = await axios.get(`${BASE_URL}/economy/allCurrency`, {
    headers: buildHeaders(apiKey),
    timeout: TIMEOUT_MS,
  });

  if (!res.data?.success) {
    throw new Error(`CollectAPI /allCurrency failed: success=false`);
  }

  const items  = res.data.result ?? [];
  const now    = new Date().toISOString();
  const forex  = {};
  let   usdTry = 0;

  for (const item of items) {
    const code = (item.code ?? item.Code ?? "").toUpperCase().trim();
    if (!WANTED_CURRENCIES.has(code)) continue;

    const buying  = parsePrice(item.buying  ?? item.Buying);
    const selling = parsePrice(item.selling ?? item.Selling);
    const rate    = buying > 0 ? buying : selling;
    const pct     = parsePct(item.changerate ?? item.Changerate ?? 0);

    if (rate <= 0) continue;

    const fsKey = `${code}TRY`;
    forex[fsKey] = {
      price:         round2(rate),
      alis:          round2(buying),
      satis:         round2(selling),
      changePercent: round2(pct),
      name:          `${code}/TRY`,
      symbol:        `${code}/TRY`,
      subLabel:      "doviz",
      currency:      "TRY",
      lastUpdated:   now,
    };

    if (code === "USD") usdTry = rate;
  }

  if (Object.keys(forex).length === 0) {
    throw new Error("CollectAPI forex: no currencies parsed");
  }

  return { forex, usdTry };
}

/** Altın fiyatlarını çeker → gold map'ine girecek format */
async function _fetchGold(apiKey) {
  const res = await axios.get(`${BASE_URL}/economy/goldPrice`, {
    headers: buildHeaders(apiKey),
    timeout: TIMEOUT_MS,
  });

  if (!res.data?.success) {
    throw new Error(`CollectAPI /goldPrice failed: success=false`);
  }

  const items = res.data.result ?? [];
  const now   = new Date().toISOString();
  const gold  = {};

  for (const item of items) {
    const rawName = (item.name ?? item.Name ?? "").trim();
    const fsKey   = GOLD_KEY_MAP[rawName];
    if (!fsKey) continue;

    const alis   = parsePrice(item.buying  ?? item.Buying);
    const satis  = parsePrice(item.selling ?? item.Selling);
    const degisim = parsePct(item.changerate ?? item.Changerate ?? 0);

    if (alis <= 0 && satis <= 0) continue;

    const alisVal  = alis  > 0 ? alis  : satis;
    const satisVal = satis > 0 ? satis : alis;
    const mid      = (alisVal + satisVal) / 2;

    if (BILEZIK_KEYS.has(fsKey)) {
      // Bilezik: gram başı fiyat — alis/satis farklı field adı
      gold[fsKey] = {
        alisgram:    round2(alisVal),
        satisgram:   round2(satisVal),
        degisim:     round2(degisim),
        subLabel:    "emtia",
        lastUpdated: now,
      };
    } else {
      gold[fsKey] = {
        alis:         round2(alisVal),
        satis:        round2(satisVal),
        degisim:      round2(degisim),
        degisimTutar: round2(mid * degisim / 100),
        subLabel:     "emtia",
        lastUpdated:  now,
      };
    }
  }

  if (Object.keys(gold).length === 0) {
    throw new Error("CollectAPI gold: no items parsed");
  }

  return gold;
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * Döviz ve altın verilerini çeker.
 * İki endpoint paralel çalışır — biri başarısız olsa diğeri hâlâ döner.
 *
 * @returns {{ forex, gold, usdTry }}
 * @throws  Her iki endpoint de başarısız olursa
 */
async function fetchForexAndGold() {
  const apiKey = process.env.COLLECT_API_KEY;
  if (!apiKey) throw new Error("COLLECT_API_KEY secret is not set");

  // İki endpoint'i paralel çalıştır
  const [forexResult, goldResult] = await Promise.allSettled([
    _fetchForex(apiKey),
    _fetchGold(apiKey),
  ]);

  const out = { forex: {}, gold: {}, usdTry: 0 };
  let anySuccess = false;

  if (forexResult.status === "fulfilled") {
    out.forex  = forexResult.value.forex;
    out.usdTry = forexResult.value.usdTry;
    anySuccess = true;
    console.log(`[collectapi] ✓ Döviz: ${Object.keys(out.forex).length} kur`);
  } else {
    console.error("[collectapi] ✗ Döviz FAILED:", forexResult.reason?.message);
  }

  if (goldResult.status === "fulfilled") {
    out.gold   = goldResult.value;
    anySuccess = true;
    console.log(`[collectapi] ✓ Altın: ${Object.keys(out.gold).length} tür`);
  } else {
    console.error("[collectapi] ✗ Altın FAILED:", goldResult.reason?.message);
  }

  if (!anySuccess) {
    throw new Error("CollectAPI: both forex and gold endpoints failed");
  }

  return out;
}

module.exports = { fetchForexAndGold };
