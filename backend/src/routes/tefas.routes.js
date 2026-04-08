'use strict';
const express   = require('express');
const tefasSvc  = require('../services/tefas.service');

const router = express.Router();

// GET /api/tefas/search?q=teknoloji
router.get('/search', async (req, res) => {
  const q = (req.query.q ?? '').trim();
  if (!q) return res.status(400).json({ error: 'Arama terimi gerekli.' });
  try {
    const funds = await tefasSvc.searchFunds(q);
    return res.json(funds);
  } catch (err) {
    return res.status(500).json({ error: 'Fon araması başarısız.' });
  }
});

// GET /api/tefas/fund/:code
router.get('/fund/:code', async (req, res) => {
  try {
    const fund = await tefasSvc.getFundDetail(req.params.code);
    if (!fund) return res.status(404).json({ error: 'Fon bulunamadı.' });
    return res.json(fund);
  } catch (err) {
    return res.status(500).json({ error: 'Fon detayı alınamadı.' });
  }
});

// GET /api/tefas/top?category=Hisse+Senedi&limit=10
router.get('/top', async (req, res) => {
  const category = (req.query.category ?? '').trim();
  const limit    = Math.min(parseInt(req.query.limit ?? '10', 10), 50);
  try {
    const funds = await tefasSvc.getTopFunds(category, limit);
    return res.json(funds);
  } catch (err) {
    return res.status(500).json({ error: 'Top fon listesi alınamadı.' });
  }
});

// GET /api/tefas/risk-analysis — portföy risk raporu
router.get('/risk-analysis', async (req, res) => {
  // TODO: JWT ile userId çekince portfolyoyu DB'den al
  const riskSvc = require('../services/risk.service');
  const portSvc = require('../services/portfolio.service');
  const mktSvc  = require('../services/market.service');

  try {
    const userId   = req.headers['x-user-id'] || 'demo';
    const profile  = req.query.profile || 'mid';
    const snapshot = await mktSvc.getMarketSnapshot().catch(() => null);
    const summary  = portSvc.computeSummary(userId, snapshot);
    const analysis = riskSvc.analyzeRisk(profile, summary.assets, null);

    return res.json({ ...analysis, portfolioValue: summary.totalValue });
  } catch (err) {
    console.error('[Risk Analysis Error]', err.message);
    return res.status(500).json({ error: 'Risk analizi başarısız.' });
  }
});

module.exports = router;
