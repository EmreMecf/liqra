'use strict';

// ── Risk Profili Tanımları ─────────────────────────────────────────────────
const RISK_PROFILES = {
  low:  { label: 'Muhafazakâr', maxEquity: 0.20, maxCrypto: 0.02, minFixed: 0.50 },
  mid:  { label: 'Dengeli',     maxEquity: 0.50, maxCrypto: 0.10, minFixed: 0.25 },
  high: { label: 'Agresif',     maxEquity: 0.80, maxCrypto: 0.20, minFixed: 0.05 },
};

// ── Varlık Tipi → Kategori ─────────────────────────────────────────────────
function _assetCategory(type) {
  switch (type) {
    case 'stock':   return 'equity';
    case 'fund':    return 'equity';    // basitleştirme — karma fon ayrımı TODO
    case 'crypto':  return 'crypto';
    case 'gold':    return 'gold';
    case 'forex':   return 'forex';
    case 'deposit': return 'fixed';
    default:        return 'other';
  }
}

/**
 * Portföy için risk skoru hesaplar (0-100)
 * Yüksek skor = yüksek risk
 */
function computeRiskScore(assets) {
  if (!assets || assets.length === 0) return 0;

  const totalVal = assets.reduce((s, a) => s + (a.marketValue ?? a.quantity * a.avgCost), 0);
  if (totalVal === 0) return 0;

  const weights = { equity: 0, crypto: 0, gold: 0, forex: 0, fixed: 0, other: 0 };
  for (const a of assets) {
    const val  = a.marketValue ?? a.quantity * a.avgCost;
    const cat  = _assetCategory(a.type);
    weights[cat] += val / totalVal;
  }

  // Ağırlıklı risk puanı (her kategori için sabit risk katsayısı)
  const score =
    weights.equity * 60 +
    weights.crypto * 95 +
    weights.gold   * 35 +
    weights.forex  * 40 +
    weights.fixed  * 10 +
    weights.other  * 50;

  return Math.min(100, Math.round(score));
}

/**
 * Risk profiline göre uyarı ve öneri listesi üretir
 * @param {string} riskProfile  'low' | 'mid' | 'high'
 * @param {Array}  assets       computeSummary().assets
 * @param {{ totalIncome, totalExpenses }} spending
 * @returns {{ score, label, warnings, suggestions, allocation }}
 */
function analyzeRisk(riskProfile, assets, spending) {
  const profile  = RISK_PROFILES[riskProfile] ?? RISK_PROFILES.mid;
  const score    = computeRiskScore(assets);
  const totalVal = assets.reduce((s, a) => s + (a.marketValue ?? a.quantity * a.avgCost), 0);

  // Dağılım yüzdeleri
  const allocation = {};
  for (const a of assets) {
    const cat = _assetCategory(a.type);
    const val = a.marketValue ?? a.quantity * a.avgCost;
    allocation[cat] = (allocation[cat] ?? 0) + val / totalVal;
  }

  const warnings    = [];
  const suggestions = [];

  // ── Kural 1: Kripto ağırlığı ────────────────────────────────────────────
  const cryptoW = allocation.crypto ?? 0;
  if (cryptoW > profile.maxCrypto) {
    const excess = ((cryptoW - profile.maxCrypto) * totalVal).toFixed(0);
    warnings.push(`Kripto ağırlığı %${(cryptoW * 100).toFixed(1)} — ${profile.label} profil için maksimum %${(profile.maxCrypto * 100).toFixed(0)}`);
    suggestions.push(`Kripto pozisyonunuzdan yaklaşık ${Number(excess).toLocaleString('tr-TR')} TL alarak TEFAS fona yönlendirin`);
  }

  // ── Kural 2: Hisse ağırlığı ─────────────────────────────────────────────
  const equityW = allocation.equity ?? 0;
  if (equityW > profile.maxEquity) {
    warnings.push(`Hisse ağırlığı %${(equityW * 100).toFixed(1)} — ${profile.label} profil için maksimum %${(profile.maxEquity * 100).toFixed(0)}`);
    suggestions.push(`Hisse yoğunluğunu azaltmak için bazı pozisyonları kâr realizasyonu ile kapatmayı değerlendirin`);
  }

  // ── Kural 3: Sabit gelir eksikliği ──────────────────────────────────────
  const fixedW = allocation.fixed ?? 0;
  if (fixedW < profile.minFixed) {
    suggestions.push(`Portföyünüze en az %${(profile.minFixed * 100).toFixed(0)} oranında vadeli mevduat veya tahvil ekleyin`);
  }

  // ── Kural 4: Tek varlık konsantrasyonu ──────────────────────────────────
  for (const a of assets) {
    const w = (a.marketValue ?? a.quantity * a.avgCost) / totalVal;
    if (w > 0.30) {
      warnings.push(`${a.name} tek başına portföyün %${(w * 100).toFixed(1)}'ini oluşturuyor — çeşitlendirme riski var`);
    }
  }

  // ── Kural 5: Acil fon kontrolü ──────────────────────────────────────────
  if (spending) {
    const monthlyExp  = spending.totalExpenses ?? 0;
    const emergencyTarget = monthlyExp * 6;
    const liquidVal   = (allocation.fixed ?? 0) * totalVal + (allocation.forex ?? 0) * totalVal;
    if (liquidVal < emergencyTarget && monthlyExp > 0) {
      suggestions.push(`Acil fonunuz ${liquidVal.toLocaleString('tr-TR', { maximumFractionDigits: 0 })} TL — aylık giderinizin 6 katı olan ${emergencyTarget.toLocaleString('tr-TR', { maximumFractionDigits: 0 })} TL'ye ulaşana kadar önce mevduat biriktirin`);
    }
  }

  // ── Kural 6: Döviz koruma ─────────────────────────────────────────────
  const forexGoldW = (allocation.forex ?? 0) + (allocation.gold ?? 0);
  if (forexGoldW < 0.10) {
    suggestions.push('Enflasyona karşı portföyünüzün en az %10\'unu altın veya dövize yatırın');
  }

  return {
    score,
    label:    _scoreLabel(score),
    warnings,
    suggestions,
    allocation: Object.fromEntries(
      Object.entries(allocation).map(([k, v]) => [k, Math.round(v * 100)])
    ),
  };
}

function _scoreLabel(score) {
  if (score < 25) return 'Çok Düşük Risk';
  if (score < 45) return 'Düşük Risk';
  if (score < 65) return 'Orta Risk';
  if (score < 80) return 'Yüksek Risk';
  return 'Çok Yüksek Risk';
}

module.exports = { computeRiskScore, analyzeRisk };
