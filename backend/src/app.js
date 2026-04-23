'use strict';
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const cron    = require('node-cron');
const config  = require('./config');
const { initFirebase, getFirestore, getMessaging } = require('./firebase');
const { globalLimiter } = require('./middleware/rateLimiter.middleware');
const aiRoutes        = require('./routes/ai.routes');
const marketRoutes    = require('./routes/market.routes');
const portfolioRoutes = require('./routes/portfolio.routes');
const ocrRoutes       = require('./routes/ocr.routes');
const tefasRoutes        = require('./routes/tefas.routes');
const notificationRoutes = require('./routes/notification.routes');
const { generateMonthlyReport } = require('./services/claude.service');
const { seedDemoPortfolio }     = require('./services/portfolio.service');

initFirebase();

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
  console.log('[CRON] Aylık raporlar başlatılıyor...');

  const db        = getFirestore();
  const messaging = getMessaging();

  if (!db || !messaging) {
    console.warn('[CRON] Firebase Admin başlatılmadı — rapor gönderilemedi.');
    return;
  }

  const monthNames = ['', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                          'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  const now = new Date();
  const monthName = `${monthNames[now.getMonth()]} ${now.getFullYear()}`;

  try {
    const usersSnap = await db.collection('users').get();
    let ok = 0, fail = 0;

    for (const userDoc of usersSnap.docs) {
      const data     = userDoc.data();
      const fcmToken = data.fcmToken;
      if (!fcmToken) continue;

      try {
        const context = {
          riskProfile:         data.riskProfile      || 'mid',
          monthlyIncome:       data.monthlyIncome     || 0,
          monthlyExpenses:     data.monthlyExpenses   || 0,
          netCash:             (data.monthlyIncome || 0) - (data.monthlyExpenses || 0),
          transactionsSummary: 'Bu aya ait işlemler analiz edildi.',
          portfolioSummary:    'Portföy verileri değerlendirildi.',
        };

        await generateMonthlyReport({ monthName, context });

        await messaging.send({
          token: fcmToken,
          notification: {
            title: `📊 ${monthName} Raporu Hazır`,
            body:  'AI asistanınız aylık finansal analizinizi tamamladı.',
          },
          data: { route: '/ai' },
        });

        ok++;
      } catch (e) {
        fail++;
        console.error(`[CRON] ${userDoc.id} raporu başarısız:`, e.message);
      }
    }

    console.log(`[CRON] ${monthName}: ${ok} başarılı, ${fail} başarısız.`);
  } catch (err) {
    console.error('[CRON] Kullanıcı listesi alınamadı:', err.message);
  }
}, { timezone: 'Europe/Istanbul' });

module.exports = app;
