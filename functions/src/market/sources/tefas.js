/**
 * tefas.js — TEFAS Fon Kataloğu Veri Kaynağı
 *
 * ── Neden yeniden yazıldı ───────────────────────────────────────────────────
 * TEFAS'ın eski public API'si (POST /api/DB/BindHistoryInfo) KAPATILDI.
 * Gerçek tarayıcıda, geçerli bot-koruma çerezleriyle, same-origin'den bile
 * şu yanıtı veriyor:
 *     { faultCode: "ERR-006", faultString: "Method not found or disabled!" }  → 404
 *
 * TEFAS sitesini Next.js'e taşıdı ve yeni bir dışa aktarma ucu açtı:
 *     POST https://www.tefas.gov.tr/api/fund-returns/export
 *     { format, listingType, fundType, locale }
 *
 * Bu uç kimlik doğrulaması, çerez ve bot koruması İSTEMEZ — sunucudan
 * doğrudan çağrılabilir (doğrulandı).
 *
 * ── Ne alıyoruz, ne alamıyoruz ──────────────────────────────────────────────
 * ✔ Fon kodu, tam ünvan, fon türü açıklaması, risk değeri (1-7)
 *   YAT 2137 + EMK 400 + BYF 37 ≈ 2574 fon
 * ✘ Birim pay değeri (fiyat) — bu uçta YOK. Fiyat yalnızca
 *   /tr/fon-detayli-analiz/{KOD} sayfasının server-render çıktısında var ve
 *   o sayfalar bot koruması arkasında. Bu yüzden fon fiyatı kullanıcı
 *   tarafından elle girilir (bkz. AddAssetSheet).
 * ✘ Getiri alanları (getiri1a/1y…) uçta mevcut ama daima null dönüyor.
 *
 * Firestore hedefi: tefas_funds/catalog
 *   { updatedAt, count, funds: [{ c: kod, n: ünvan, t: tür, r: risk, k: kategori }] }
 *
 * Tek doküman kullanılıyor (≈315 KB, 1 MB limitinin altında): istemci
 * katalog için 2574 değil TEK okuma yapar.
 */

"use strict";

const axios = require("axios");

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const EXPORT_URL = "https://www.tefas.gov.tr/api/fund-returns/export";
const TIMEOUT_MS = 45_000;

/** k = Firestore'a yazılan kısa kategori kodu */
const FUND_TYPES = [
  { code: "YAT", label: "Menkul Kıymet Yatırım Fonu" },
  { code: "EMK", label: "Emeklilik Fonu" },
  { code: "BYF", label: "Borsa Yatırım Fonu" },
];

const HEADERS = {
  "Content-Type": "application/json",
  "Accept":       "application/json",
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Referer": "https://www.tefas.gov.tr/tr/fon-getirileri",
};

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const str = (v) => (v == null ? "" : String(v).trim());

function toRisk(v) {
  const n = parseInt(v, 10);
  return Number.isFinite(n) && n >= 1 && n <= 7 ? n : 0;
}

// ─── Tek fon tipi çekimi ──────────────────────────────────────────────────────

async function _fetchType(fundType) {
  const res = await axios.post(
    EXPORT_URL,
    { format: "json", listingType: "return", fundType, locale: "tr" },
    { headers: HEADERS, timeout: TIMEOUT_MS },
  );

  if (!Array.isArray(res.data)) {
    throw new Error(`TEFAS ${fundType}: beklenmeyen yanıt tipi`);
  }
  return res.data;
}

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * Tüm fon tiplerinin kataloğunu çeker.
 *
 * Bir fon tipi başarısız olsa dahi diğerleri döner (Promise.allSettled).
 * Hiçbiri başarılı olmazsa BOŞ dizi döner — sahte veri ÜRETİLMEZ, çağıran
 * taraf mevcut Firestore verisini olduğu gibi bırakır.
 *
 * @returns {Promise<Array<{c:string,n:string,t:string,r:number,k:string}>>}
 */
async function fetchFundCatalog() {
  const results = await Promise.allSettled(
    FUND_TYPES.map((t) => _fetchType(t.code)),
  );

  const byCode = new Map();

  results.forEach((res, i) => {
    const { code: fundType, label } = FUND_TYPES[i];

    if (res.status !== "fulfilled") {
      console.error(
        `[tefas] ✗ ${fundType} başarısız:`,
        res.reason?.response?.status ?? res.reason?.message,
      );
      return;
    }

    let added = 0;
    for (const item of res.value) {
      const code = str(item.fonKodu).toUpperCase();
      if (!code) continue;
      // Aynı kod birden fazla tipte görünürse ilki kalsın
      if (byCode.has(code)) continue;

      byCode.set(code, {
        c: code,
        n: str(item.fonUnvan) || code,
        t: str(item.fonTurAciklama) || label,
        r: toRisk(item.riskDegeri),
        k: fundType,
      });
      added++;
    }
    console.log(`[tefas] ✓ ${fundType}: ${added} fon (${label})`);
  });

  const list = [...byCode.values()].sort((a, b) => a.c.localeCompare(b.c, "tr"));
  console.log(`[tefas] Katalog toplam ${list.length} fon`);
  return list;
}

module.exports = { fetchFundCatalog };
