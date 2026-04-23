'use strict';
require('dotenv').config();

module.exports = {
  port:    parseInt(process.env.PORT || '3000', 10),
  env:     process.env.NODE_ENV || 'development',
  isDev:   process.env.NODE_ENV !== 'production',

  anthropic: {
    apiKey: process.env.ANTHROPIC_API_KEY,
    model:  process.env.CLAUDE_MODEL || 'claude-sonnet-4-6',
    maxTokens: parseInt(process.env.CLAUDE_MAX_TOKENS || '2000', 10),
  },

  db: {
    url: process.env.DATABASE_URL,
  },

  jwt: {
    secret:          process.env.JWT_SECRET || 'dev-secret-change-in-prod',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES  || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES || '7d',
  },

  rateLimit: {
    aiPerHour:     parseInt(process.env.AI_RATE_LIMIT_PER_HOUR || '20', 10),
    globalPerMin:  parseInt(process.env.GLOBAL_RATE_LIMIT_PER_MIN || '60', 10),
  },
};
