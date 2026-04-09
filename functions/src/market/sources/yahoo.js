/**
 * yahoo.js — BIST Hisse Senedi Veri Kaynağı
 *
 * Kaynak: CollectAPI /economy/hisseSenedi
 *   - 611 BIST hissesi, hacme göre sıralı
 *   - GCP sunucularından sorunsuz çalışır (aynı CollectAPI key)
 *   - rate (günlük %), lastprice, hacim, min, max alanları
 *
 * Strateji: API'den gelen 611 hisseden hacim sıralamasına göre
 *   ilk MAX_STOCKS tanesini Firestore'a yazar.
 *   MAX_STOCKS = 100 (Firestore 1MB döküman limiti dahilinde)
 *
 * Firestore şeması:
 *   market/live_prices.stocks → BIST hisseleri (subLabel: "bist")
 */

"use strict";

const axios            = require("axios");
const { getFirestore } = require("firebase-admin/firestore");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const COLLECT_BASE  = "https://api.collectapi.com/economy";
const TIMEOUT_MS    = 15_000;
const FIRESTORE_DOC = "market/live_prices";

/** Hacim sıralamasına göre kaç hisse kaydedilecek */
const MAX_STOCKS = 100;

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((isNaN(n) || n == null ? 0 : Number(n)) * 100) / 100;

/**
 * Hisse adını Türkçe karakterlerle düzenler.
 * CollectAPI büyük harf İngilizce döndürüyor (TURK HAVA YOLLARI).
 * Title case'e çeviririz: "Türk Hava Yolları" gibi değil ama
 * en azından baş harfi büyük yapıyoruz.
 */
function formatName(raw) {
  if (!raw) return raw;
  return raw
    .split(" ")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(" ");
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * CollectAPI'den BIST hisselerini çeker, hacme göre ilk MAX_STOCKS'u Firestore'a yazar.
 *
 * @returns {{ bist: object, xu100: object|null, usdTryFromYahoo: 0 }}
 */
async function fetchStocks() {
  const now    = new Date().toISOString();
  const apikey = process.env.COLLECT_API_KEY;

  if (!apikey) throw new Error("COLLECT_API_KEY secret eksik");

  // ── 1. CollectAPI isteği ─────────────────────────────────────────────────
  let raw;
  try {
    const res = await axios.get(`${COLLECT_BASE}/hisseSenedi`, {
      params:  { gunlukYuzde: true },
      headers: {
        authorization:  `apikey ${apikey}`,
        "content-type": "application/json",
      },
      timeout: TIMEOUT_MS,
    });
    raw = Array.isArray(res.data?.result) ? res.data.result : [];
  } catch (err) {
    throw new Error(`CollectAPI hisseSenedi başarısız: ${err.message}`);
  }

  if (raw.length === 0) throw new Error("CollectAPI: Boş liste döndü");

  // ── 2. Hacme göre zaten sıralı geliyor — ilk MAX_STOCKS'u al ─────────────
  //    Fiyatı 0 olan veya kodu olmayan hisseleri filtrele
  const top = raw
    .filter((x) => x?.code && x.lastprice > 0)
    .slice(0, MAX_STOCKS);

  // ── 3. Firestore objesi oluştur ───────────────────────────────────────────
  const bist = {};

  for (const item of top) {
    const code = item.code.toUpperCase();
    bist[code] = {
      price:         round2(item.lastprice),
      changePercent: round2(item.rate),
      name:          formatName(item.text) || code,
      symbol:        code,
      currency:      "TRY",
      subLabel:      "bist",
      hacim:         item.hacim ?? 0,      // işlem hacmi (sıralama için)
      min:           round2(item.min),
      max:           round2(item.max),
      lastUpdated:   now,
    };
  }

  const bistCount = Object.keys(bist).length;
  console.log(`[collectapi/bist] ✓ ${bistCount} BIST hissesi (${raw.length} toplam)`);

  if (bistCount === 0) throw new Error("CollectAPI: Hiçbir BIST hissesi parse edilemedi");

  // ── 4. XU100 endeks ───────────────────────────────────────────────────────
  // API hacim sıralamasıyla geldiği için XU100 listede olmayabilir.
  // Ayrıca parametreli istek yapıyoruz.
  let xu100 = null;
  try {
    const xuRes = await axios.get(`${COLLECT_BASE}/hisseSenedi`, {
      params:  { gunlukYuzde: true, hisse: "XU100" },
      headers: {
        authorization:  `apikey ${apikey}`,
        "content-type": "application/json",
      },
      timeout: TIMEOUT_MS,
    });
    const xuList = Array.isArray(xuRes.data?.result) ? xuRes.data.result : [];
    const xuItem = xuList.find((x) => x?.code?.toUpperCase() === "XU100");
    if (xuItem && xuItem.lastprice > 0) {
      xu100 = {
        price:         round2(xuItem.lastprice),
        changePercent: round2(xuItem.rate),
      };
      console.log(`[collectapi/bist] ✓ XU100: ${xu100.price}  Δ${xu100.changePercent}%`);
    }
  } catch (_) {
    console.warn("[collectapi/bist] XU100 alınamadı — endeks gösterilmeyecek");
  }

  // ── 5. Firestore'a yaz ───────────────────────────────────────────────────
  const db     = getFirestore();
  const docRef = db.doc(FIRESTORE_DOC);
  await docRef.set({ stocks: bist }, { merge: true });

  return { bist, xu100, usdTryFromYahoo: 0 };
}

module.exports = { fetchStocks };
