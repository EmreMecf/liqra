/**
 * Liqra — Firebase Cloud Functions entry point
 *
 * Exports:
 *   fetchMarketData — every 2 minutes → market/live_prices
 *                     Kaynaklar: Binance (kripto) + Yahoo (hisse) +
 *                     CollectAPI (döviz+altın) + TEFAS (fon)
 *                     Fault-tolerant: Promise.allSettled, dot-notation Firestore update
 */

const { initializeApp } = require("firebase-admin/app");
initializeApp();

const { fetchMarketData } = require("./market/fetchMarketData");
const { fetchCampaigns }  = require("./campaigns/fetchCampaigns");

module.exports = { fetchMarketData, fetchCampaigns };
