'use strict';
const express      = require('express');
const rateLimit    = require('express-rate-limit');
const Joi          = require('joi');
const claudeService = require('../services/claude.service');
const config       = require('../config');

const router = express.Router();

// ── Rate Limit — kullanıcı başı saatte 20 AI isteği ─────────────────────────
const aiLimiter = rateLimit({
  windowMs:  60 * 60 * 1000, // 1 saat
  max:       config.rateLimit.aiPerHour,
  keyGenerator: (req) => req.user?.id ?? req.ip,
  standardHeaders: true,
  legacyHeaders:  false,
  message: {
    error: 'Saatlik AI istek limitini aştınız. Lütfen bekleyin.',
    retryAfter: 3600,
  },
});

// ── Validasyon şemaları ───────────────────────────────────────────────────────
const chatSchema = Joi.object({
  message: Joi.string().min(1).max(2000).required(),
  mode:    Joi.string().valid(
    'budget_audit', 'portfolio_advisor', 'goal_tracker', 'free_chat'
  ).required(),
  context: Joi.object({
    riskProfile:          Joi.string().required(),
    monthlyIncome:        Joi.number().min(0).required(),
    monthlyExpenses:      Joi.number().min(0).required(),
    netCash:              Joi.number().required(),
    portfolioSummary:     Joi.string().allow('').required(),
    transactionsSummary:  Joi.string().allow('').required(),
    goalTitle:            Joi.string().allow('').optional(),
    goalProgress:         Joi.number().min(0).max(100).optional(),
    goalDeadline:         Joi.string().optional(),
  }).required(),
  history: Joi.array().items(
    Joi.object({
      role:    Joi.string().valid('user', 'assistant').required(),
      content: Joi.string().required(),
    })
  ).max(20).default([]),
});

// ── POST /api/ai/chat ─────────────────────────────────────────────────────────
router.post('/chat', aiLimiter, async (req, res) => {
  const { error, value } = chatSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }

  try {
    const result = await claudeService.sendMessage({
      message: value.message,
      mode:    value.mode,
      context: value.context,
      history: value.history,
    });

    return res.json(result);
  } catch (err) {
    console.error('[AI Chat Error]', err.message);

    if (err.status === 429) {
      return res.status(429).json({
        error: 'Claude API kapasitesi aşıldı. Kısa süre içinde tekrar deneyin.',
      });
    }

    return res.status(500).json({
      error: 'AI servisi geçici olarak kullanılamıyor.',
    });
  }
});

// ── GET /api/ai/modes — desteklenen modlar ────────────────────────────────────
router.get('/modes', (req, res) => {
  res.json({
    modes: [
      { key: 'budget_audit',      label: 'Bütçe Denetimi',     icon: '📊' },
      { key: 'portfolio_advisor', label: 'Yatırım Tavsiyesi',  icon: '📈' },
      { key: 'goal_tracker',      label: 'Hedef Analizi',      icon: '🎯' },
      { key: 'free_chat',         label: 'Serbest Sohbet',     icon: '💬' },
    ],
  });
});

module.exports = router;
