'use strict';
const express       = require('express');
const marketService = require('../services/market.service');

const router = express.Router();

// GET /api/market/snapshot — tüm canlı piyasa verisi
router.get('/snapshot', async (req, res) => {
  try {
    const data = await marketService.getMarketSnapshot();
    return res.json(data);
  } catch (err) {
    console.error('[Market Error]', err.message);
    return res.status(503).json({ error: 'Piyasa verisi alınamadı.' });
  }
});

module.exports = router;
