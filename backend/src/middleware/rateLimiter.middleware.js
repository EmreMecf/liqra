'use strict';
const rateLimit = require('express-rate-limit');
const config    = require('../config');

/// Global rate limiter — tüm endpointler
const globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 dakika
  max: config.rateLimit.globalPerMin,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çok fazla istek gönderildi. Lütfen bekleyin.' },
});

/// AI endpointleri için sıkı limiter
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 saat
  max: config.rateLimit.aiPerHour,
  keyGenerator: (req) => req.user?.id ?? req.ip,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: `Saatlik AI istek limiti (${config.rateLimit.aiPerHour}) aşıldı.`,
    retryAfter: 3600,
  },
});

module.exports = { globalLimiter, aiLimiter };
