'use strict';

// ── In-memory portfolyo deposu ─────────────────────────────────────────────
// TODO: PostgreSQL'e taşı (FAZ 5)
const portfolios = new Map(); // userId → Asset[]

let _nextId = 1;

/**
 * Kullanıcının tüm varlıklarını döner
 */
function getPortfolio(userId) {
  return portfolios.get(userId) ?? [];
}

/**
 * Yeni varlık ekler
 * @param {string} userId
 * @param {{ symbol, name, type, quantity, avgCost, currency }} dto
 */
function addAsset(userId, dto) {
  const assets = getPortfolio(userId);
  const asset = {
    id:        String(_nextId++),
    symbol:    dto.symbol.toUpperCase(),
    name:      dto.name,
    type:      dto.type,           // 'stock' | 'fund' | 'gold' | 'crypto' | 'forex' | 'deposit'
    quantity:  Number(dto.quantity),
    avgCost:   Number(dto.avgCost),
    currency:  dto.currency ?? 'TRY',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  portfolios.set(userId, [...assets, asset]);
  return asset;
}

/**
 * Varlık günceller (quantity veya avgCost)
 */
function updateAsset(userId, assetId, dto) {
  const assets = getPortfolio(userId);
  const idx    = assets.findIndex(a => a.id === assetId);
  if (idx === -1) return null;

  const updated = {
    ...assets[idx],
    ...(dto.quantity  != null ? { quantity:  Number(dto.quantity)  } : {}),
    ...(dto.avgCost   != null ? { avgCost:   Number(dto.avgCost)   } : {}),
    ...(dto.name      != null ? { name:      dto.name              } : {}),
    updatedAt: new Date().toISOString(),
  };
  const newList = [...assets];
  newList[idx]  = updated;
  portfolios.set(userId, newList);
  return updated;
}

/**
 * Varlık siler
 */
function deleteAsset(userId, assetId) {
  const assets = getPortfolio(userId);
  const exists = assets.some(a => a.id === assetId);
  if (!exists) return false;
  portfolios.set(userId, assets.filter(a => a.id !== assetId));
  return true;
}

/**
 * Portföy özetini hesaplar (güncel fiyatlar market.service'ten enjekte edilir)
 * @param {string} userId
 * @param {{ gold, forex, crypto }} marketSnapshot
 */
function computeSummary(userId, marketSnapshot) {
  const assets    = getPortfolio(userId);
  let   totalCost = 0;
  let   totalVal  = 0;

  const enriched = assets.map(a => {
    const currentPrice = _resolvePrice(a, marketSnapshot);
    const costBasis    = a.quantity * a.avgCost;
    const marketVal    = a.quantity * currentPrice;
    totalCost += costBasis;
    totalVal  += marketVal;
    return {
      ...a,
      currentPrice,
      marketValue:   marketVal,
      gainLoss:      marketVal - costBasis,
      gainLossPct:   costBasis > 0 ? ((marketVal - costBasis) / costBasis) * 100 : 0,
    };
  });

  return {
    assets:         enriched,
    totalCost,
    totalValue:     totalVal,
    totalGainLoss:  totalVal - totalCost,
    gainLossPct:    totalCost > 0 ? ((totalVal - totalCost) / totalCost) * 100 : 0,
    updatedAt:      new Date().toISOString(),
  };
}

/**
 * Varlık tipine göre güncel fiyatı çözer
 */
function _resolvePrice(asset, snap) {
  if (!snap) return asset.avgCost;

  switch (asset.type) {
    case 'gold':
      return snap.gold?.gramTRY ?? asset.avgCost;
    case 'crypto': {
      const key = `${asset.symbol}TRY`;
      return snap.crypto?.[key]?.price ?? asset.avgCost;
    }
    case 'forex': {
      const key = `${asset.symbol}TRY`;
      return snap.forex?.[key] ?? asset.avgCost;
    }
    // Hisse / fon: TODO gerçek fiyat API entegrasyonu
    default:
      return asset.avgCost;
  }
}

// ── Demo veri (geliştirme ortamı) ──────────────────────────────────────────
function seedDemoPortfolio(userId = 'demo') {
  if (getPortfolio(userId).length > 0) return;
  const demo = [
    { symbol: 'GARAN',   name: 'Garanti BBVA',           type: 'stock',   quantity: 500,   avgCost: 118.40,  currency: 'TRY' },
    { symbol: 'BIMAS',   name: 'BİM Mağazaları',          type: 'stock',   quantity: 200,   avgCost: 412.50,  currency: 'TRY' },
    { symbol: 'ALTINGR', name: 'Gram Altın',              type: 'gold',    quantity: 15,    avgCost: 2980.00, currency: 'TRY' },
    { symbol: 'BTC',     name: 'Bitcoin',                 type: 'crypto',  quantity: 0.025, avgCost: 2650000, currency: 'TRY' },
    { symbol: 'TTE',     name: 'TEB Teknoloji Fonu',      type: 'fund',    quantity: 1000,  avgCost: 3.42,    currency: 'TRY' },
  ];
  demo.forEach(d => addAsset(userId, d));
}

module.exports = { getPortfolio, addAsset, updateAsset, deleteAsset, computeSummary, seedDemoPortfolio };
