/**
 * fetchTefasPrices — hafta içi her gün saat 19:00 TSI'de çalışır
 *
 * Kaynak: RapidAPI TEFAS (tefas-api.p.rapidapi.com)
 * API key: Firebase Remote Config → "rapidapi_tefas_key"
 *
 * Yazar:
 *   market/live_prices.topFunds → [{ code, name, type, return1y, price }]
 *   Tüm fonlar: market/tefas_funds/{code} → { code, name, type, price, return1d, return1m, return1y }
 *
 * Not: 1000+ fon varsa batch write kullanılır (Firestore 500 doc limit).
 */

const { onSchedule }               = require("firebase-functions/v2/scheduler");
const { getFirestore, WriteBatch, FieldValue } = require("firebase-admin/firestore");
const { getRemoteConfig }          = require("firebase-admin/remote-config");
const axios                        = require("axios");

const RAPIDAPI_HOST = "tefas-api.p.rapidapi.com";
const BASE_URL      = `https://${RAPIDAPI_HOST}`;
const TOP_N         = 10; // En iyi 10 fonu live_prices.topFunds'a yaz

// ── Yardımcılar ───────────────────────────────────────────────────────────────

function toNum(v) {
  if (v == null) return 0;
  const n = typeof v === "number" ? v : parseFloat(String(v).replace(",", "."));
  return isNaN(n) ? 0 : n;
}

function toStr(v) {
  return v == null ? "" : String(v).trim();
}

/** Remote Config'den RapidAPI key al */
async function getApiKey() {
  try {
    const rc     = getRemoteConfig();
    const tmpl   = await rc.getTemplate();
    const param  = tmpl.parameters?.rapidapi_tefas_key;
    const val    = param?.defaultValue?.value ?? "";
    return val;
  } catch {
    return "";
  }
}

/** RapidAPI response'unu TefasFund listesine dönüştür */
function parseFunds(data) {
  let list;
  if (Array.isArray(data))          list = data;
  else if (Array.isArray(data?.data))   list = data.data;
  else if (Array.isArray(data?.result)) list = data.result;
  else if (Array.isArray(data?.funds))  list = data.funds;
  else return [];

  return list
    .filter((item) => typeof item === "object" && item !== null)
    .map((item) => ({
      code:          toStr(item.fundCode  ?? item.code    ?? item.FonKod   ?? ""),
      name:          toStr(item.fundName  ?? item.name    ?? item.FonUnvan ?? ""),
      type:          toStr(item.category  ?? item.fundType?? item.FonTur   ?? "Fon"),
      price:         toNum(item.price     ?? item.BirimPayDegeri           ?? 0),
      return1d:      toNum(item.return1d  ?? item.GunlukGetiri             ?? 0),
      return1m:      toNum(item.return1m  ?? item.AylikGetiri              ?? 0),
      return1y:      toNum(item.return1y  ?? item.BirYillikGetiri          ?? 0),
    }))
    .filter((f) => f.code.length > 0);
}

// ── Ana fonksiyon ─────────────────────────────────────────────────────────────

exports.fetchTefasPrices = onSchedule(
  {
    schedule:       "0 19 * * 1-5",   // Hafta içi 19:00 TSI
    timeZone:       "Europe/Istanbul",
    memory:         "512MiB",
    timeoutSeconds: 120,
    region:         "europe-west1",
  },
  async () => {
    const db     = getFirestore();
    const apiKey = await getApiKey();

    if (!apiKey) {
      console.error("[fetchTefasPrices] RapidAPI key bulunamadı (Remote Config: rapidapi_tefas_key).");
      return;
    }

    // ── TEFAS returns endpoint ─────────────────────────────────────────────────
    const today     = new Date();
    const yearAgo   = new Date(today);
    yearAgo.setFullYear(yearAgo.getFullYear() - 1);

    const fmt = (d) =>
      `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;

    let funds = [];

    try {
      const res = await axios.get(`${BASE_URL}/api/v1/funds/returns`, {
        params: {
          fundType:  "YAT",
          startDate: fmt(yearAgo),
          endDate:   fmt(today),
        },
        headers: {
          "x-rapidapi-key":  apiKey,
          "x-rapidapi-host": RAPIDAPI_HOST,
          Accept:            "application/json",
        },
        timeout: 30_000,
      });
      funds = parseFunds(res.data);
      console.log(`[fetchTefasPrices] ${funds.length} fon alındı.`);
    } catch (e) {
      if (e.response?.status === 429) {
        console.error("[fetchTefasPrices] 429 Rate limit — yarın tekrar denenecek.");
      } else {
        console.error("[fetchTefasPrices] API hatası:", e.message);
      }
      return;
    }

    if (funds.length === 0) {
      console.warn("[fetchTefasPrices] Fon listesi boş — yazılmadı.");
      return;
    }

    // ── topFunds → market/live_prices.topFunds ─────────────────────────────────
    const sorted   = [...funds].sort((a, b) => b.return1y - a.return1y);
    const topFunds = sorted.slice(0, TOP_N).map((f) => ({
      code:          f.code,
      name:          f.name,
      type:          f.type,
      returnPercent: f.return1y,
      price:         f.price,
    }));

    const liveRef = db.doc("market/live_prices");
    await liveRef.set(
      { topFunds, topFundsUpdatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );

    // ── Tüm fonlar → tefas_funds/{code} (batch write) ──────────────────
    const BATCH_SIZE = 400; // Firestore 500 doc limiti
    const nowISO     = new Date().toISOString();

    for (let i = 0; i < funds.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = funds.slice(i, i + BATCH_SIZE);

      for (const f of chunk) {
        const ref = db.doc(`tefas_funds/${f.code}`);
        batch.set(ref, {
          code:      f.code,
          name:      f.name,
          type:      f.type,
          price:     f.price,
          return1d:  f.return1d,
          return1m:  f.return1m,
          return1y:  f.return1y,
          updatedAt: nowISO,
        });
      }

      await batch.commit();
      console.log(`[fetchTefasPrices] Batch yazıldı: ${i + 1}–${Math.min(i + BATCH_SIZE, funds.length)}`);
    }

    console.log(`[fetchTefasPrices] Tamamlandı: ${funds.length} fon, ${topFunds.length} top fund.`);
  }
);
