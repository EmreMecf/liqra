/**
 * yahoo.js — BIST Hisse Senedi Veri Kaynağı
 *
 * Kaynak: CollectAPI /economy/hisseSenedi
 *   - Canlı BIST fiyatları, günlük değişim yüzdesi
 *   - GCP sunucularından sorunsuz çalışır (aynı CollectAPI key)
 *   - Basic plan: 10.000 istek/ay → her 2 dk = 21.600 istek/ay
 *     → Sadece hacimce en yüksek 20 hisseyi çeker (1 istek/run ✓)
 *
 * ABD hisseleri kaldırıldı (kullanıcı talebi).
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

// Gösterilecek BIST hisseleri (CollectAPI kod eşleşmesi)
const BIST_META = {
  GARAN:  { name: "Garanti BBVA",       icon: "🏦" },
  BIMAS:  { name: "BİM Mağazalar",      icon: "🛒" },
  THYAO:  { name: "Türk Hava Yolları",  icon: "✈️"  },
  AKBNK:  { name: "Akbank",             icon: "🏦" },
  ASELS:  { name: "Aselsan",            icon: "🛡️"  },
  EREGL:  { name: "Ereğli Demir Çelik",icon: "⚙️"  },
  SISE:   { name: "Şişecam",            icon: "🔬" },
  KCHOL:  { name: "Koç Holding",        icon: "🏭" },
  ISCTR:  { name: "İş Bankası C",       icon: "🏦" },
  SAHOL:  { name: "Sabancı Holding",    icon: "🏢" },
  TCELL:  { name: "Turkcell",           icon: "📱" },
  ARCLK:  { name: "Arçelik",            icon: "🏠" },
  FROTO:  { name: "Ford Otomotiv",      icon: "🚗" },
  KOZAL:  { name: "Koza Altın",         icon: "🥇" },
  YKBNK:  { name: "Yapı Kredi",         icon: "🏦" },
  TUPRS:  { name: "Tüpraş",            icon: "⛽" },
  TOASO:  { name: "Tofaş Oto",         icon: "🚙" },
  PGSUS:  { name: "Pegasus",            icon: "✈️"  },
  VESTL:  { name: "Vestel",            icon: "📺" },
  SOKM:   { name: "Şok Marketler",      icon: "🛍️"  },
};

const WANTED_CODES = new Set(Object.keys(BIST_META));

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const round2 = (n) => Math.round((isNaN(n) || n == null ? 0 : Number(n)) * 100) / 100;

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * CollectAPI'den BIST hisselerini çeker, Firestore'a yazar.
 * fetchMarketData.js tarafından çağrılır.
 *
 * @returns {{ bist: object, xu100: null, usdTryFromYahoo: 0 }}
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

  // ── 2. İstediğimiz hisseleri filtrele & parse et ─────────────────────────
  const bist = {};

  for (const item of raw) {
    const code = item?.code?.toUpperCase?.();
    if (!code || !WANTED_CODES.has(code)) continue;

    const price = round2(item.lastprice);
    if (price <= 0) continue;

    const meta       = BIST_META[code];
    bist[code] = {
      price,
      changePercent: round2(item.rate),        // günlük % (pozitif/negatif)
      name:          meta?.name ?? item.text ?? code,
      icon:          meta?.icon ?? "📈",
      symbol:        code,
      currency:      "TRY",
      subLabel:      "bist",
      lastUpdated:   now,
    };
  }

  const bistCount = Object.keys(bist).length;
  console.log(`[collectapi/bist] ✓ ${bistCount}/${WANTED_CODES.size} BIST hissesi`);

  if (bistCount === 0) throw new Error("CollectAPI: Hiçbir BIST hissesi parse edilemedi");

  // ── 3. XU100 endeks (ayrı endpoint) ─────────────────────────────────────
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

  // ── 4. Firestore'a yaz ───────────────────────────────────────────────────
  const db     = getFirestore();
  const docRef = db.doc(FIRESTORE_DOC);
  await docRef.set({ stocks: bist }, { merge: true });

  return { bist, xu100, usdTryFromYahoo: 0 };
}

module.exports = { fetchStocks };
