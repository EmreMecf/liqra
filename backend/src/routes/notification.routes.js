'use strict';
const express   = require('express');
const Joi       = require('joi');
const notifSvc  = require('../services/notification.service');
const { verifyToken } = require('../middleware/checkRole.middleware');

const router = express.Router();

// Token kaydı/bildirim gönderimi kullanıcıya özeldir
router.use(verifyToken);

// ── POST /api/notifications/register ──────────────────────────────────────────
// Cihaz FCM token'ını kaydet
router.post('/register', async (req, res) => {
  const { error, value } = Joi.object({
    token: Joi.string().required(),
  }).validate(req.body);

  if (error) return res.status(400).json({ error: error.details[0].message });

  // userId gövdeden DEĞİL, doğrulanmış token'dan alınır
  notifSvc.registerToken(req.user.id, value.token);
  return res.json({ success: true });
});

// ── POST /api/notifications/test ───────────────────────────────────────────────
// Geliştirme ortamında test bildirimi gönder
router.post('/test', async (req, res) => {
  const { error, value } = Joi.object({
    type:   Joi.string().valid(
      'budget_alert', 'monthly_report', 'portfolio_alert'
    ).default('monthly_report'),
  }).validate(req.body);

  if (error) return res.status(400).json({ error: error.details[0].message });

  const token = notifSvc.getToken(req.user.id);
  if (!token) {
    return res.status(404).json({ error: 'Bu kullanıcı için token bulunamadı.' });
  }

  let result;
  switch (value.type) {
    case 'budget_alert':
      result = await notifSvc.sendBudgetAlert(token, {
        category: 'Yeme-İçme', spent: 5680, limit: 4000,
      });
      break;
    case 'portfolio_alert':
      result = await notifSvc.sendPortfolioAlert(token, {
        asset: 'GARAN', changePercent: -3.42,
      });
      break;
    default:
      result = await notifSvc.sendMonthlyReport(token, 'Mart 2026');
  }

  return res.json(result);
});

module.exports = router;
