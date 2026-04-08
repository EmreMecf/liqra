/**
 * fetchMarketData — Liqra Market Data Pipeline v2
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * Her 2 dakikada bir çalışır. Fault-tolerant: herhangi bir kaynak başarısız
 * olsa dahi diğerleri Firestore'a yazmaya devam eder. Başarısız kaynağın eski
 * verisi silinmez (Firestore update() dot-notation kullanımı sayesinde).
 *
 * Kaynak izolasyonu:
 *   ┌─────────────┬─────────────────────────────┬──────────────────┐
 *   │ Kaynak      │ Veri                        │ Firestore Alan   │
 *   ├─────────────┼─────────────────────────────┼──────────────────┤
 *   │ Binance     │ Kripto TRY çiftleri         │ prices.BTC_TRY…  │
 *   │ Yahoo       │ BIST 20 + ABD 10 + XU100    │ stocks.*, us_stocks.* │
 *   │ CollectAPI  │ Döviz (USD,EUR,GBP,CHF)     │ prices.USDTRY…   │
 *   │             │ Altın (12 tür)              │ gold.*           │
 *   │ TEFAS       │ Fon fiyatları (dummy)       │ funds.*          │
 *   └─────────────┴─────────────────────────────┴──────────────────┘
 *
 * Firestore Dökümanı: market/live_prices
 * Yazar: update() ile dot-notation — merge:true değil, true key-level upsert
 *
 * @see sources/binance.js
 * @see sources/yahoo.js
 * @see sources/collectapi.js
 * @see sources/tefas.js
 */

"use strict";

const { onSchedule }              = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const { fetchCrypto }       = require("./sources/binance");
const { fetchStocks }       = require("./sources/yahoo");
const { fetchForexAndGold } = require("./sources/collectapi");
const { fetchFunds }        = require("./sources/tefas");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

/** Cloud Scheduler iki kez tetikleyebilir — bu süre içinde tekrar çalışmaz */
const RATE_LIMIT_MS = 90_000; // 90 saniye

const FIRESTORE_DOC = "market/live_prices";

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

/**
 * İç içe objeyi dot-notation flat objeye çevirir.
 *
 * Neden lazım: Firestore'a { prices: { BTC_TRY: {...} } } set() ile yazarsan
 * prices map'indeki diğer tüm anahtarlar SİLİNİR. update() ile dot-notation
 * kullanınca sadece verilen anahtarlar güncellenir, geri kalanlar dokunulmaz.
 *
 * Örnek:
 *   flatten("prices", { BTC_TRY: { price: 1 } })
 *   → { "prices.BTC_TRY": { price: 1 } }
 */
function flatten(prefix, obj) {
  const result = {};
  if (!obj || typeof obj !== "object") return result;
  for (const [key, val] of Object.entries(obj)) {
    result[`${prefix}.${key}`] = val;
  }
  return result;
}

/**
 * Promise.allSettled sonuçlarını işler — başarılı olanları döner, hatayı loglar
 */
function settle(label, result, handler) {
  if (result.status === "fulfilled") {
    try {
      handler(result.value);
    } catch (parseErr) {
      console.error(`[fetchMarketData] ${label} parse hatası:`, parseErr);
    }
  } else {
    console.error(
      `[fetchMarketData] ✗ ${label} BAŞARISIZ:`,
      result.reason?.message ?? result.reason
    );
  }
}

// ─── Ana Cloud Function ───────────────────────────────────────────────────────

exports.fetchMarketData = onSchedule(
  {
    schedule:       "every 2 minutes",
    timeZone:       "Europe/Istanbul",
    memory:         "512MiB",
    timeoutSeconds: 120,
    region:         "europe-west1",
    // Firebase Secret Manager'dan COLLECT_API_KEY'i enjekte eder
    // "firebase functions:secrets:set COLLECT_API_KEY" ile ayarla
    secrets:        ["COLLECT_API_KEY"],
  },
  async () => {
    const startMs = Date.now();
    const db      = getFirestore();
    const ref     = db.doc(FIRESTORE_DOC);

    // ── 1. Rate-limit Guard ──────────────────────────────────────────────────
    const snap = await ref.get();
    if (snap.exists) {
      const lastFetch = snap.data()?.lastFetch?.toDate?.();
      if (lastFetch && startMs - lastFetch.getTime() < RATE_LIMIT_MS) {
        console.log("[fetchMarketData] Rate limit — atlandı.");
        return;
      }
    }

    // ── 2. Tüm kaynakları paralel başlat ────────────────────────────────────
    //
    // Promise.allSettled: bir kaynak hata verse dahi diğerleri tamamlanır.
    // Hiçbir zaman throw etmez — sonuçlar { status, value | reason } olarak döner.
    //
    console.log("[fetchMarketData] Tüm kaynaklar başlatılıyor…");

    const [cryptoRes, stocksRes, forexGoldRes, fundsRes] = await Promise.allSettled([
      fetchCrypto(),
      fetchStocks(),           // usdTry önce forex'ten gelecek; yoksa Yahoo'dan
      fetchForexAndGold(),
      fetchFunds(),
    ]);

    // ── 3. Başarılı sonuçlardan USD/TRY kurunu al ────────────────────────────
    //
    // ABD hisselerini TRY'ye çevirmek için kullanılır.
    // Öncelik: CollectAPI → Yahoo fallback (kendi içinde kullandı zaten)
    let usdTry = 0;
    if (forexGoldRes.status === "fulfilled") {
      usdTry = forexGoldRes.value.usdTry ?? 0;
    }

    // ── 4. Firestore güncelleme objesi oluştur ───────────────────────────────
    //
    // dot-notation key'ler: sadece başarılı kaynaklar dahil edilir.
    // Başarısız kaynağa ait alan Firestore'da ESKİ VERİYİ KORUR.

    const updates = {};

    // Kripto → prices map
    settle("Binance (Kripto)", cryptoRes, ({ prices }) => {
      Object.assign(updates, flatten("prices", prices));
    });

    // Hisseler — stocks ve us_stocks'u yahoo.js kendi { merge: true } ile yazdı.
    // Burada yalnızca XU100 endeks fiyatını prices map'ine ekliyoruz.
    settle("Yahoo (Hisse)", stocksRes, ({ xu100 }) => {
      if (xu100) {
        updates["prices.XU100"] = {
          price:         xu100.price,
          changePercent: xu100.changePercent,
          name:          "BIST100",
          symbol:        "XU100",
          subLabel:      "endeks",
          currency:      "TRY",
          lastUpdated:   new Date().toISOString(),
        };
      }
    });

    // Döviz + Altın — collectapi.js kendi prices/gold map'lerini merge:true ile yazdı.
    // Burada yalnızca USD/TRY kurunu ABD hisseleri için kaydediyoruz (usdTry).
    settle("CollectAPI (Döviz+Altın)", forexGoldRes, (_data) => {
      // Firestore yazımı collectapi.js içinde yapıldı — burada ek işlem yok.
    });

    // Fonlar → funds map
    settle("TEFAS (Fon)", fundsRes, (funds) => {
      Object.assign(updates, flatten("funds", funds));
    });

    // ── 5. Hiçbir veri yoksa yaz ─────────────────────────────────────────────
    const dataKeyCount = Object.keys(updates).length;
    if (dataKeyCount === 0) {
      console.error("[fetchMarketData] Hiçbir kaynaktan veri alınamadı — Firestore yazılmadı.");
      return;
    }

    // ── 6. Meta alanları ekle ────────────────────────────────────────────────
    const durationMs = Date.now() - startMs;

    updates["lastFetch"]          = FieldValue.serverTimestamp();
    updates["meta.version"]       = "2.0";
    updates["meta.fetchDuration"] = durationMs;
    updates["meta.updatedAt"]     = new Date().toISOString();
    updates["meta.sources.crypto"]     = cryptoRes.status;
    updates["meta.sources.stocks"]     = stocksRes.status;
    updates["meta.sources.forexGold"]  = forexGoldRes.status;
    updates["meta.sources.funds"]      = fundsRes.status;

    // ── 7. Firestore'a yaz ───────────────────────────────────────────────────
    //
    // Adım 1: Döküman yoksa oluştur (set merge:true sadece üst-seviye merge)
    // Adım 2: update() ile dot-notation — key bazlı güncelleme
    //         Başarısız kaynağa ait alt-map'ler DOKUNULMAZ kalır.

    if (!snap.exists) {
      await ref.set({ _initialized: true, lastFetch: FieldValue.serverTimestamp() }, { merge: true });
    }

    await ref.update(updates);

    // ── 8. Özet log ─────────────────────────────────────────────────────────
    const successSources = [
      cryptoRes.status    === "fulfilled" ? "Binance ✓"    : "Binance ✗",
      stocksRes.status    === "fulfilled" ? "Yahoo ✓"      : "Yahoo ✗",
      forexGoldRes.status === "fulfilled" ? "CollectAPI ✓" : "CollectAPI ✗",
      fundsRes.status     === "fulfilled" ? "TEFAS ✓"      : "TEFAS ✗",
    ].join("  ");

    console.log(
      `[fetchMarketData] Tamamlandı — ${durationMs}ms | ${dataKeyCount} alan | ${successSources}`
    );
  }
);
