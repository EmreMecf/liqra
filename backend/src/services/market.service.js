'use strict';
const axios  = require('axios');

// ── Canlı Piyasa Verisi ───────────────────────────────────────────────────────

async function getMarketSnapshot() {
  const [gold, forex, crypto] = await Promise.allSettled([
    fetchGold(),
    fetchForex(),
    fetchCrypto(),
  ]);

  return {
    gold:   gold.status   === 'fulfilled' ? gold.value   : getMockGold(),
    forex:  forex.status  === 'fulfilled' ? forex.value  : getMockForex(),
    crypto: crypto.status === 'fulfilled' ? crypto.value : getMockCrypto(),
    updatedAt: new Date().toISOString(),
  };
}

// Gram altın — Collect API
async function fetchGold() {
  // TODO: COLLECT_API_KEY ile gerçek istek
  // const res = await axios.get('https://api.collectapi.com/economy/goldPrice', {
  //   headers: { authorization: `apikey ${process.env.COLLECT_API_KEY}` },
  // });
  return getMockGold();
}

// Döviz — Frankfurter API (ücretsiz)
async function fetchForex() {
  try {
    const res = await axios.get(
      'https://api.frankfurter.app/latest?from=USD,EUR,GBP&to=TRY',
      { timeout: 5000 }
    );
    const rates = res.data.rates?.TRY ?? {};
    return {
      USDTRY: rates.USD ?? 32.87,
      EURTRY: rates.EUR ?? 35.42,
      GBPTRY: rates.GBP ?? 41.12,
    };
  } catch {
    return getMockForex();
  }
}

// Kripto — Binance (ücretsiz)
async function fetchCrypto() {
  try {
    const [btc, eth] = await Promise.all([
      axios.get('https://api.binance.com/api/v3/ticker/24hr?symbol=BTCTRY', { timeout: 5000 }),
      axios.get('https://api.binance.com/api/v3/ticker/24hr?symbol=ETHTRY', { timeout: 5000 }),
    ]);
    return {
      BTCTRY: {
        price:         parseFloat(btc.data.lastPrice),
        changePercent: parseFloat(btc.data.priceChangePercent),
      },
      ETHTRY: {
        price:         parseFloat(eth.data.lastPrice),
        changePercent: parseFloat(eth.data.priceChangePercent),
      },
    };
  } catch {
    return getMockCrypto();
  }
}

// ── Mock fallback'ler ─────────────────────────────────────────────────────────
const getMockGold  = () => ({ gramTRY: 3267.45, changePercent: 0.82 });
const getMockForex = () => ({ USDTRY: 32.87, EURTRY: 35.42, GBPTRY: 41.12 });
const getMockCrypto = () => ({
  BTCTRY: { price: 2847320, changePercent: 2.87 },
  ETHTRY: { price: 142650,  changePercent: 3.41 },
});

module.exports = { getMarketSnapshot };
