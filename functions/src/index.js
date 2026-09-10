/**
 * Liqra — Firebase Cloud Functions giriş noktası
 *
 * Yalnızca burada export edilenler deploy edilir.
 *
 *   fetchMarketData — 2 dakikada bir → market/live_prices
 *                     Kaynaklar: Binance (kripto),
 *                     CollectAPI (döviz + altın + BIST hissesi)
 *   fetchTefasFunds — her gün 19:30  → tefas_funds/catalog (fon kataloğu;
 *                     bu uçta fiyat YOK, fiyatı kullanıcı elle girer)
 *   fetchCampaigns  — her gün 03:00  → bank_campaigns/ (örnek veri,
 *                     isSample: true; bağlı canlı banka kaynağı yok)
 *   fetchNews       — saatlik        → news/ (5 RSS kaynağı)
 *   onUserCreated   — Firestore tetikleyici → role: 'personal' claim
 *
 * Yahoo Finance KULLANILMIYOR. sources/collectapi_stocks.js eskiden
 * yahoo.js adındaydı; BIST verisi CollectAPI /economy/hisseSenedi ucundan
 * gelir. Eski adı hatırlayıp Yahoo aramaya kalkma.
 *
 * fetchMarketData 90 saniyelik tekrar koruması ve Promise.allSettled ile
 * çalışır: bir kaynak düşerse diğerleri yazılmaya devam eder.
 */

const { initializeApp } = require("firebase-admin/app");
initializeApp();

const { fetchMarketData } = require("./market/fetchMarketData");
const { fetchCampaigns }  = require("./campaigns/fetchCampaigns");
const { fetchNews }       = require("./news/fetchNews");
const { onUserCreated }   = require("./auth/onUserCreated");
const { fetchTefasFunds } = require("./funds/fetchTefasFunds");

module.exports = {
  fetchMarketData,
  fetchTefasFunds,
  fetchCampaigns,
  fetchNews,
  onUserCreated,
};
