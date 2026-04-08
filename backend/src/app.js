'use strict';
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const cron    = require('node-cron');
const config  = require('./config');
const { globalLimiter } = require('./middleware/rateLimiter.middleware');
const aiRoutes        = require('./routes/ai.routes');
const marketRoutes    = require('./routes/market.routes');
const portfolioRoutes = require('./routes/portfolio.routes');
const ocrRoutes       = require('./routes/ocr.routes');
const tefasRoutes        = require('./routes/tefas.routes');
const notificationRoutes = require('./routes/notification.routes');
const { generateMonthlyReport } = require('./services/claude.service');
const { seedDemoPortfolio }     = require('./services/portfolio.service');
const notifSvc                  = require('./services/notification.service');

const app = express();

// ── Güvenlik middleware'leri ─────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: config.isDev ? '*' : ['https://muhasebe.app'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));  // OCR base64 için artırıldı
app.use(globalLimiter);

// ── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) =>
  res.json({ status: 'ok', env: config.env, ts: new Date().toISOString() })
);

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/ai',        aiRoutes);
app.use('/api/market',    marketRoutes);
app.use('/api/portfolio', portfolioRoutes);
app.use('/api/ocr',       ocrRoutes);
app.use('/api/tefas',         tefasRoutes);
app.use('/api/notifications', notificationRoutes);

// ── Demo seed (geliştirme ortamı) ─────────────────────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  seedDemoPortfolio('demo');
}

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) =>
  res.status(404).json({ error: `${req.path} bulunamadı.` })
);

// ── Global hata yakalayıcı ────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[Unhandled Error]', err);
  res.status(500).json({ error: 'Sunucu hatası.' });
});

// ── Aylık Rapor Cron Job — her ayın 1'i gece 00:00 ───────────────────────────
cron.schedule('0 0 1 * *', async () => {
  console.log('[CRON] Aylık rapor oluşturuluyor...');
  try {
    const monthNames = ['', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                            'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    const now = new Date();
    const monthName = `${monthNames[now.getMonth()]} ${now.getFullYear()}`;

    // TODO: Her kullanıcı için ayrı rapor oluştur (DB'den kullanıcı listesi al)
    const mockContext = {
      riskProfile: 'mid', monthlyIncome: 45000,
      monthlyExpenses: 23000, netCash: 22000,
      transactionsSummary: 'Bu ay harcama verisi',
      portfolioSummary: 'Portföy özeti',
    };

    const report = await generateMonthlyReport({
      monthName,
      context: mockContext,
    });

    console.log(`[CRON] ${monthName} raporu oluşturuldu. Tokens: ${report.content?.length}`);
    // TODO: DB'den kullanıcı listesi al, her birine bildirim gönder
    // Örnek: tüm kayıtlı token'lara gönder
    const { _tokens } = require('./services/notification.service');
    // (In-memory demo — production'da DB sorgusu yapılacak)
    await notifSvc.sendMonthlyReport('demo_token', monthName).catch(() => {});
  } catch (err) {
    console.error('[CRON] Rapor hatası:', err.message);
  }
}, { timezone: 'Europe/Istanbul' });

module.exports = app;
