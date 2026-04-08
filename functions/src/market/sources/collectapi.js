/**
 * collectapi.js — Döviz & Altın Veri Kaynağı
 *
 * Endpoints:
 *   POST /economy/allCurrency → USD, EUR, GBP, CHF kurları
 *   POST /economy/goldPrice   → Gram, Çeyrek, Yarım, Tam, Ons altın...
 *
 * Günlük Yüzde Değişim Stratejisi (iki katmanlı):
 *
 *   Seçenek 1 — API changerate kullan:
 *     CollectAPI her sembol için `changerate` alanı döndürür.
 *     Ücretsiz planda genellikle 0 gelir veya formatı değişken olabilir.
 *     Sıfır olmayan değer varsa direkt kullanılır.
 *
 *   Seçenek 2 — Firestore günlük snapshot'tan hesapla:
 *     Eğer API'den gelen changerate == 0 ise, "market/daily_snapshot"
 *     dökümanındaki bir önceki günün kapanış fiyatıyla karşılaştırılır:
 *       change = ((bugün - dün) / dün) × 100
 *     Snapshot her gün ilk çalışmada güncellenir (tarih değişince).
 *     Bu şekilde 2dk'da bir çalışan fonksiyon gerçek günlük değişimi hesaplar.
 *
 * Firestore şeması:
 *   market/live_prices  → prices (döviz) + gold (altın) map'leri
 *   market/daily_snapshot → { date, prices: {USDTRY: number, ...},
 *                              gold: {gram: number, ...} }
 */

"use strict";

const axios            = require("axios");
const { getFirestore } = require("firebase-admin/firestore");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const BASE_URL         = "https://api.collectapi.com";
const TIMEOUT_MS       = 12_000;
const LIVE_DOC         = "market/live_prices";
const SNAPSHOT_DOC     = "market/daily_snapshot";

const WANTED_CURRENCIES = new Set(["USD", "EUR", "GBP", "CHF"]);

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
 */
function parsePrice(str) {
  if (str == null)            return 0;
  if (typeof str === "number") return isNaN(str) ? 0 : str;
  const cleaned = String(str).replace(/\./g, "").replace(",", ".");
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

/**
 * "% 0,50" | "%-0,50" | "0.50" | "%1.2" → 1.2
 * CollectAPI changerate formatı tutarsız olabiliyor — tüm varyantları karşıla.
 */
function parsePct(str) {
  if (str == null) return 0;
  const cleaned = String(str)
    .replace(/[%\s]/g, "")   // % ve boşluk
    .replace(",", ".");        // Türkçe ondalık
  const n = parseFloat(cleaned);
  return isNaN(n) ? 0 : n;
}

function buildHeaders(apiKey) {
  return {
    "Authorization": `apikey ${apiKey}`,
    "content-type":  "application/json",
  };
}

// ─── Günlük Snapshot ──────────────────────────────────────────────────────────

/**
 * Firestore'dan günlük snapshot'ı okur.
 * Döner: { date: "YYYY-MM-DD", prices: {USDTRY: n, ...}, gold: {gram: n, ...} }
 * Snapshot yoksa veya okunamazsa null döner.
 */
async function _readSnapshot() {
  try {
    const snap = await getFirestore().doc(SNAPSHOT_DOC).get();
    if (!snap.exists) return null;
    return snap.data();
  } catch (err) {
    console.warn("[collectapi] Snapshot okunamadı:", err.message);
    return null;
  }
}

/**
 * Günlük snapshot'ı günceller — sadece tarih değişmişse yazar.
 * Bu sayede gün içinde 2dk'da bir çalışan fonksiyon snapshot'ı bozmaz.
 *
 * @param {string} today          "YYYY-MM-DD" formatında bugünün tarihi
 * @param {Object} prevSnapshot   Mevcut snapshot verisi (null olabilir)
 * @param {Object} priceMap       { USDTRY: number, ... }
 * @param {Object} goldMap        { gram: number, ... }
 */
async function _updateSnapshotIfNeeded(today, prevSnapshot, priceMap, goldMap) {
  if (prevSnapshot?.date === today) return; // Bugün zaten güncellendi

  const ref = getFirestore().doc(SNAPSHOT_DOC);
  try {
    await ref.set(
      { date: today, prices: priceMap, gold: goldMap },
      { merge: false }, // Tam üzerine yaz — günlük kapanış snapshot'ı
    );
    console.log(`[collectapi] ✓ Günlük snapshot güncellendi (${today})`);
  } catch (err) {
    console.warn("[collectapi] Snapshot yazılamadı:", err.message);
  }
}

/**
 * Günlük yüzde değişimi hesaplar.
 *
 * Öncelik sırası:
 *   1. API'den gelen changerate (sıfır değilse güvenilir veri)
 *   2. Firestore snapshot'ındaki dünkü fiyatla manual hesap
 *   3. Her ikisi de yoksa/sıfırsa → 0
 *
 * @param {number} apiChangerate  CollectAPI'nin döndürdüğü değer (0 olabilir)
 * @param {number} currentPrice   Güncel fiyat
 * @param {number|undefined} prevPrice  Snapshot'tan önceki fiyat
 */
function resolveChangePercent(apiChangerate, currentPrice, prevPrice) {
  // Seçenek 1: API changerate sıfır değilse kullan
  if (apiChangerate !== 0) {
    return round2(apiChangerate);
  }

  // Seçenek 2: Manuel hesap — önceki günün fiyatı varsa
  if (prevPrice && prevPrice > 0 && currentPrice > 0) {
    return round2(((currentPrice - prevPrice) / prevPrice) * 100);
  }

  return 0;
}

// ─── API Çekicileri ───────────────────────────────────────────────────────────

async function _fetchForex(apiKey) {
  const res = await axios.get(`${BASE_URL}/economy/allCurrency`, {
    headers: buildHeaders(apiKey),
    timeout: TIMEOUT_MS,
  });

  if (!res.data?.success) {
    throw new Error("CollectAPI /allCurrency: success=false");
  }

  return res.data.result ?? [];
}

async function _fetchGold(apiKey) {
  const res = await axios.get(`${BASE_URL}/economy/goldPrice`, {
    headers: buildHeaders(apiKey),
    timeout: TIMEOUT_MS,
  });

  if (!res.data?.success) {
    throw new Error("CollectAPI /goldPrice: success=false");
  }

  return res.data.result ?? [];
}

// ─── Parse & Normalize ────────────────────────────────────────────────────────

/**
 * Döviz listesini parse eder.
 * Döner: { forexMap: { USDTRY: {...}, ... }, snapshotPrices: { USDTRY: n, ... }, usdTry: n }
 */
function _parseForex(items, snapshot, now) {
  const forexMap       = {};
  const snapshotPrices = {}; // Yarın için snapshot'a kaydedilecek
  let   usdTry         = 0;

  for (const item of items) {
    const code = (item.code ?? item.Code ?? "").toUpperCase().trim();
    if (!WANTED_CURRENCIES.has(code)) continue;

    const buying  = parsePrice(item.buying  ?? item.Buying);
    const selling = parsePrice(item.selling ?? item.Selling);
    const rate    = buying > 0 ? buying : selling;
    if (rate <= 0) continue;

    const apiPct    = parsePct(item.changerate ?? item.Changerate ?? 0);
    const fsKey     = `${code}TRY`;
    const prevPrice = snapshot?.prices?.[fsKey];

    const changePercent = resolveChangePercent(apiPct, rate, prevPrice);

    forexMap[fsKey] = {
      price:         round2(rate),
      alis:          round2(buying),
      satis:         round2(selling),
      changePercent,
      name:          `${code}/TRY`,
      symbol:        `${code}/TRY`,
      subLabel:      "doviz",        // Flutter bu değerle filtreler
      currency:      "TRY",
      lastUpdated:   now,
    };

    snapshotPrices[fsKey] = rate;
    if (code === "USD") usdTry = rate;
  }

  return { forexMap, snapshotPrices, usdTry };
}

/**
 * Altın listesini parse eder.
 * Döner: { goldMap: { gram: {...}, ... }, snapshotGold: { gram: n, ... } }
 */
function _parseGold(items, snapshot, now) {
  const goldMap      = {};
  const snapshotGold = {};

  for (const item of items) {
    const rawName = (item.name ?? item.Name ?? "").trim();
    const fsKey   = GOLD_KEY_MAP[rawName];
    if (!fsKey) continue;

    const alis    = parsePrice(item.buying  ?? item.Buying);
    const satis   = parsePrice(item.selling ?? item.Selling);
    const apiPct  = parsePct(item.changerate ?? item.Changerate ?? 0);

    if (alis <= 0 && satis <= 0) continue;

    const alisVal  = alis  > 0 ? alis  : satis;
    const satisVal = satis > 0 ? satis : alis;
    const midPrice = (alisVal + satisVal) / 2;

    const prevPrice     = snapshot?.gold?.[fsKey];
    const changePercent = resolveChangePercent(apiPct, midPrice, prevPrice);

    if (BILEZIK_KEYS.has(fsKey)) {
      goldMap[fsKey] = {
        alisgram:    round2(alisVal),
        satisgram:   round2(satisVal),
        degisim:     changePercent,
        subLabel:    "emtia",
        lastUpdated: now,
      };
    } else {
      goldMap[fsKey] = {
        alis:         round2(alisVal),
        satis:        round2(satisVal),
        degisim:      changePercent,
        degisimTutar: round2(midPrice * changePercent / 100),
        subLabel:     "emtia",       // Flutter bu değerle filtreler
        lastUpdated:  now,
      };
    }

    snapshotGold[fsKey] = midPrice;
  }

  return { goldMap, snapshotGold };
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * Döviz ve altın verilerini çeker, değişimleri hesaplar, Firestore'a yazar.
 *
 * @returns {{ forex, gold, usdTry }}
 * @throws  Her iki endpoint de başarısız olursa
 */
async function fetchForexAndGold() {
  const apiKey = process.env.COLLECT_API_KEY;
  if (!apiKey) throw new Error("COLLECT_API_KEY secret ayarlanmamış");

  const now   = new Date().toISOString();
  const today = now.slice(0, 10); // "YYYY-MM-DD"

  // ── 1. Önceki günün snapshot'ını oku ──────────────────────────────────────
  const snapshot = await _readSnapshot();
  const isNewDay = snapshot?.date !== today;
  if (isNewDay) {
    console.log(`[collectapi] Yeni gün tespit edildi (${today}) — snapshot güncellenecek`);
  }

  // ── 2. API'den paralel çek ────────────────────────────────────────────────
  const [forexResult, goldResult] = await Promise.allSettled([
    _fetchForex(apiKey),
    _fetchGold(apiKey),
  ]);

  const out        = { forex: {}, gold: {}, usdTry: 0 };
  let   anySuccess = false;

  let snapshotPrices = snapshot?.prices ?? {};
  let snapshotGold   = snapshot?.gold   ?? {};

  // ── 3. Döviz parse & changePercent çözümle ───────────────────────────────
  if (forexResult.status === "fulfilled") {
    const { forexMap, snapshotPrices: newPrices, usdTry } =
      _parseForex(forexResult.value, snapshot, now);

    out.forex  = forexMap;
    out.usdTry = usdTry;
    snapshotPrices = newPrices; // Snapshot için güncel fiyatlar
    anySuccess = true;

    // Log: hangi semboller API'den, hangileri snapshot'tan aldı
    for (const [key, val] of Object.entries(forexMap)) {
      const src = parsePct(forexResult.value
        .find(i => `${(i.code ?? "").toUpperCase()}TRY` === key)?.changerate ?? 0) !== 0
        ? "API"
        : snapshot?.prices?.[key] ? "snapshot" : "—";
      console.log(`[collectapi] ${key}: ${val.price} TRY  Δ${val.changePercent}%  (kaynak: ${src})`);
    }
  } else {
    console.error("[collectapi] ✗ Döviz FAILED:", forexResult.reason?.message);
  }

  // ── 4. Altın parse & changePercent çözümle ───────────────────────────────
  if (goldResult.status === "fulfilled") {
    const { goldMap, snapshotGold: newGold } =
      _parseGold(goldResult.value, snapshot, now);

    out.gold   = goldMap;
    snapshotGold = newGold;
    anySuccess = true;

    console.log(`[collectapi] ✓ Altın: ${Object.keys(goldMap).length} tür`);
  } else {
    console.error("[collectapi] ✗ Altın FAILED:", goldResult.reason?.message);
  }

  if (!anySuccess) {
    throw new Error("CollectAPI: döviz ve altın endpoint'lerinin ikisi de başarısız");
  }

  // ── 5. Firestore'a yaz — merge:true ──────────────────────────────────────
  //
  // prices ve gold map'leri güncellenir; stocks, us_stocks, funds dokunulmaz.
  const payload = {};
  if (Object.keys(out.forex).length > 0) payload.prices = out.forex;
  if (Object.keys(out.gold).length  > 0) payload.gold   = out.gold;

  if (Object.keys(payload).length > 0) {
    await getFirestore().doc(LIVE_DOC).set(payload, { merge: true });
    console.log("[collectapi] ✓ Firestore yazıldı (prices + gold, merge:true)");
  }

  // ── 6. Günlük snapshot'ı güncelle (sadece yeni gün ise) ──────────────────
  await _updateSnapshotIfNeeded(today, snapshot, snapshotPrices, snapshotGold);

  return out;
}

module.exports = { fetchForexAndGold };
