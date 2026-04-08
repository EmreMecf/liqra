/**
 * tefas.js — TEFAS Fon Verisi Kaynağı
 *
 * DURUM: Şimdilik dummy/statik veri döner.
 *
 * Gerçek entegrasyon için seçenekler:
 *   1. tefas-crawler npm paketi (bakımsız olabilir)
 *   2. fonanaliz.com / fundturkey.com scraping
 *   3. TEFAS resmi sitesi: https://www.tefas.gov.tr/FonAnaliz.aspx
 *      Parametre: FONKODU (örn: MAC, IPB, TTE...)
 *
 * Firestore şeması (market/live_prices.funds):
 * {
 *   "MAC": { name, price, changePercent, subLabel: "fon", lastUpdated },
 *   "IPB": { ... },
 * }
 */

"use strict";

// ─── Statik Fon Listesi (Dummy) ───────────────────────────────────────────────

/**
 * Popüler TEFAS fonları — gerçek entegrasyon gelene kadar
 * Flutter tarafı bu veriyi "fon" subLabel ile filtreler.
 *
 * Fiyatlar dummy. Gerçek entegrasyon için bu fonksiyonu güncelle.
 */
const DUMMY_FUNDS = [
  { code: "MAC", name: "Mavi Çatı Karma Fonu",         price: 2.45,  changePercent:  0.82 },
  { code: "IPB", name: "İş Portföy BIST30 Endeks Fon", price: 5.13,  changePercent:  1.24 },
  { code: "TTE", name: "Tacirler Portföy Teknoloji Fon",price: 8.67,  changePercent: -0.35 },
  { code: "GAF", name: "Garanti BBVA Portföy Hisse",   price: 3.21,  changePercent:  2.10 },
  { code: "YAS", name: "Yapı Kredi Altın Fonu",        price: 12.90, changePercent:  0.45 },
];

// ─── Ana Fonksiyon ────────────────────────────────────────────────────────────

/**
 * TEFAS fon verilerini döner.
 *
 * @returns {{ [code: string]: Object }} — `funds` map'ine yazılacak veriler
 */
async function fetchFunds() {
  const now   = new Date().toISOString();
  const funds = {};

  for (const f of DUMMY_FUNDS) {
    funds[f.code] = {
      price:         f.price,
      changePercent: f.changePercent,
      name:          f.name,
      symbol:        f.code,
      subLabel:      "fon",
      isDummy:       true, // Flutter bu flag'i görünce "Yakında" gösterebilir
      lastUpdated:   now,
    };
  }

  console.log(`[tefas] ℹ️  Dummy data — ${DUMMY_FUNDS.length} fon`);
  return funds;
}

module.exports = { fetchFunds };

/*
 * ── GERÇEK ENTEGRASYON NOTLARI ─────────────────────────────────────────────
 *
 * 1. TEFAS API (Resmi — Auth gerekir):
 *    POST https://www.tefas.gov.tr/api/DB/BindHistoryInfo
 *    Body: { fontip: "YAT", bastarih: "...", bittarih: "..." }
 *    Sonuç: JSON array [{ FONKODU, FIYAT, TEDPAY, ... }]
 *
 * 2. Axios ile scraping (basit):
 *    const res = await axios.get(
 *      `https://www.tefas.gov.tr/FonAnaliz.aspx?ql=${code}`,
 *      { headers: { 'User-Agent': 'Mozilla/5.0 ...' } }
 *    );
 *    // HTML parse için cheerio kullanılabilir
 *
 * 3. npm paketi (son kontrol edilmeli):
 *    npm install tefas-crawler
 *    const tefas = require('tefas-crawler');
 *    const data = await tefas.fetch('MAC');
 *
 * Entegrasyon hazır olduğunda isDummy: false yapılacak.
 */
