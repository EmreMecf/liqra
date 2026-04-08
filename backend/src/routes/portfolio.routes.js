'use strict';
const express         = require('express');
const Joi             = require('joi');
const portfolioSvc    = require('../services/portfolio.service');
const marketSvc       = require('../services/market.service');

const router = express.Router();

// ── Validasyon şemaları ────────────────────────────────────────────────────

const assetSchema = Joi.object({
  symbol:   Joi.string().max(20).required(),
  name:     Joi.string().max(100).required(),
  type:     Joi.string().valid('stock', 'fund', 'gold', 'crypto', 'forex', 'deposit').required(),
  quantity: Joi.number().positive().required(),
  avgCost:  Joi.number().positive().required(),
  currency: Joi.string().length(3).default('TRY'),
});

const updateSchema = Joi.object({
  name:     Joi.string().max(100),
  quantity: Joi.number().positive(),
  avgCost:  Joi.number().positive(),
}).min(1);

// ── Helper: userId (JWT olmadan demo userId) ───────────────────────────────
// TODO: JWT middleware eklenince req.user.id kullan
const getUserId = (req) => req.headers['x-user-id'] || 'demo';

// ── GET /api/portfolio ─────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const userId   = getUserId(req);
    const snapshot = await marketSvc.getMarketSnapshot().catch(() => null);
    const summary  = portfolioSvc.computeSummary(userId, snapshot);
    return res.json(summary);
  } catch (err) {
    console.error('[Portfolio GET Error]', err.message);
    return res.status(500).json({ error: 'Portföy alınamadı.' });
  }
});

// ── POST /api/portfolio/assets ─────────────────────────────────────────────
router.post('/assets', async (req, res) => {
  const { error, value } = assetSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });

  try {
    const userId = getUserId(req);
    const asset  = portfolioSvc.addAsset(userId, value);
    return res.status(201).json(asset);
  } catch (err) {
    console.error('[Portfolio ADD Error]', err.message);
    return res.status(500).json({ error: 'Varlık eklenemedi.' });
  }
});

// ── PUT /api/portfolio/assets/:id ─────────────────────────────────────────
router.put('/assets/:id', async (req, res) => {
  const { error, value } = updateSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });

  try {
    const userId  = getUserId(req);
    const updated = portfolioSvc.updateAsset(userId, req.params.id, value);
    if (!updated) return res.status(404).json({ error: 'Varlık bulunamadı.' });
    return res.json(updated);
  } catch (err) {
    console.error('[Portfolio UPDATE Error]', err.message);
    return res.status(500).json({ error: 'Varlık güncellenemedi.' });
  }
});

// ── DELETE /api/portfolio/assets/:id ──────────────────────────────────────
router.delete('/assets/:id', async (req, res) => {
  try {
    const userId  = getUserId(req);
    const deleted = portfolioSvc.deleteAsset(userId, req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Varlık bulunamadı.' });
    return res.status(204).send();
  } catch (err) {
    console.error('[Portfolio DELETE Error]', err.message);
    return res.status(500).json({ error: 'Varlık silinemedi.' });
  }
});

module.exports = router;
