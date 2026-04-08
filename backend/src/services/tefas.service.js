'use strict';
const axios = require('axios');

// ── TEFAS API ──────────────────────────────────────────────────────────────
// Resmi TEFAS API: https://www.tefas.gov.tr
// Ücretsiz, kayıt gerektirmez — rate limit ~30 istek/dakika

const TEFAS_BASE = 'https://www.tefas.gov.tr/api/DB';

/**
 * Fon ara — isim veya kod ile
 * @param {string} query — fon adı veya kodu (örn: "TTE", "Garanti", "teknoloji")
 * @returns {Promise<Fund[]>}
 */
async function searchFunds(query) {
  try {
    const res = await axios.post(
      `${TEFAS_BASE}/BindingFundList`,
      {
        fontip:     'YAT',
        fonkategori: '',
        bastarih:   _today(),
        bittarih:   _today(),
      },
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 8000,
      }
    );

    const funds = res.data?.data ?? [];
    const q     = query.toLowerCase();

    return funds
      .filter(f =>
        f.FONKODU?.toLowerCase().includes(q) ||
        f.FONUNVAN?.toLowerCase().includes(q)
      )
      .slice(0, 20)
      .map(_mapFund);
  } catch (err) {
    console.warn('[TEFAS Search Error]', err.message);
    return _mockFunds(query);
  }
}

/**
 * Belirli fonun güncel verisi
 * @param {string} code — fon kodu (örn: "TTE")
 */
async function getFundDetail(code) {
  try {
    const res = await axios.post(
      `${TEFAS_BASE}/BindingFundInfo`,
      {
        fonkod:   code.toUpperCase(),
        bastarih: _sevenDaysAgo(),
        bittarih: _today(),
      },
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 8000,
      }
    );

    const data = res.data?.data?.[0];
    if (!data) return null;

    return {
      code:            data.FONKODU,
      name:            data.FONUNVAN,
      price:           Number(data.BIRIMPAYFIYATI),
      dailyReturn:     Number(data.GUNLUKGETIRI),
      monthlyReturn:   Number(data.AYLIKGETIRI),
      yearlyReturn:    Number(data.YILLIKGETIRI),
      totalAssets:     Number(data.PORTFOYBUYUKLUGU),
      category:        data.FONKATEGORI,
      riskLevel:       Number(data.RISKDEGERI),
      managementFee:   Number(data.YONETIMUCRETIORAN),
      updatedAt:       _today(),
    };
  } catch (err) {
    console.warn('[TEFAS Detail Error]', err.message);
    return null;
  }
}

/**
 * Kategori bazlı en iyi fonlar (1 aylık getiriye göre sıralı)
 * @param {string} category — 'Hisse Senedi' | 'Borçlanma Araçları' | 'Karma' | 'Altın' | 'Para Piyasası'
 */
async function getTopFunds(category, limit = 10) {
  try {
    const res = await axios.post(
      `${TEFAS_BASE}/BindingFundList`,
      {
        fontip:      'YAT',
        fonkategori: category,
        bastarih:    _today(),
        bittarih:    _today(),
      },
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 8000,
      }
    );

    const funds = res.data?.data ?? [];
    return funds
      .map(_mapFund)
      .sort((a, b) => b.monthlyReturn - a.monthlyReturn)
      .slice(0, limit);
  } catch (err) {
    console.warn('[TEFAS Top Funds Error]', err.message);
    return _mockTopFunds(category);
  }
}

// ── Yardımcılar ────────────────────────────────────────────────────────────

function _mapFund(f) {
  return {
    code:          f.FONKODU,
    name:          f.FONUNVAN,
    price:         Number(f.BIRIMPAYFIYATI ?? 0),
    dailyReturn:   Number(f.GUNLUKGETIRI   ?? 0),
    monthlyReturn: Number(f.AYLIKGETIRI    ?? 0),
    yearlyReturn:  Number(f.YILLIKGETIRI   ?? 0),
    totalAssets:   Number(f.PORTFOYBUYUKLUGU ?? 0),
    category:      f.FONKATEGORI ?? '',
    riskLevel:     Number(f.RISKDEGERI ?? 3),
  };
}

function _today() {
  return new Date().toLocaleDateString('tr-TR');
}

function _sevenDaysAgo() {
  const d = new Date();
  d.setDate(d.getDate() - 7);
  return d.toLocaleDateString('tr-TR');
}

// ── Mock fallback'ler ──────────────────────────────────────────────────────

function _mockFunds(query) {
  const all = [
    { code: 'TTE', name: 'TEB Teknoloji Girişim Fonu',        price: 4.21,  dailyReturn: 0.42,  monthlyReturn: 8.3,  yearlyReturn: 62.4, totalAssets: 2_400_000_000, category: 'Hisse Senedi', riskLevel: 5 },
    { code: 'GAF', name: 'Garanti Portföy Teknoloji Fonu',     price: 9.87,  dailyReturn: -0.21, monthlyReturn: 5.1,  yearlyReturn: 48.2, totalAssets: 1_800_000_000, category: 'Hisse Senedi', riskLevel: 5 },
    { code: 'AKP', name: 'Ak Portföy Altın Fonu',              price: 2.14,  dailyReturn: 0.65,  monthlyReturn: 4.2,  yearlyReturn: 38.7, totalAssets: 3_200_000_000, category: 'Altın',        riskLevel: 3 },
    { code: 'YAS', name: 'Yapı Kredi Para Piyasası Fonu',      price: 1.45,  dailyReturn: 0.10,  monthlyReturn: 2.8,  yearlyReturn: 31.2, totalAssets: 5_100_000_000, category: 'Para Piyasası', riskLevel: 1 },
    { code: 'IEF', name: 'İş Portföy Karma Fon',               price: 6.32,  dailyReturn: 0.18,  monthlyReturn: 3.4,  yearlyReturn: 27.8, totalAssets: 2_900_000_000, category: 'Karma',        riskLevel: 3 },
  ];
  const q = query.toLowerCase();
  return all.filter(f =>
    f.code.toLowerCase().includes(q) ||
    f.name.toLowerCase().includes(q)
  );
}

function _mockTopFunds(category) {
  return _mockFunds(category || '').slice(0, 5);
}

module.exports = { searchFunds, getFundDetail, getTopFunds };
