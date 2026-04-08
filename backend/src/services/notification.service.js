'use strict';
// Firebase Admin SDK — FCM push göndermek için
// TODO: npm install firebase-admin
// TODO: serviceAccountKey.json dosyasını backend/config/ klasörüne ekle

let admin = null;

function _getAdmin() {
  if (admin) return admin;
  try {
    admin = require('firebase-admin');
    if (!admin.apps.length) {
      const serviceAccount = require('../../config/serviceAccountKey.json');
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
  } catch (err) {
    console.warn('[FCM] Firebase Admin SDK yüklenemedi:', err.message);
    admin = null;
  }
  return admin;
}

// ── FCM Mesaj Gönderme ────────────────────────────────────────────────────────

/**
 * Tek cihaza push bildirim gönder
 * @param {string} fcmToken  — Cihazın FCM token'ı
 * @param {{ title, body, route, data }} payload
 */
async function sendToDevice(fcmToken, { title, body, route, data = {} }) {
  const sdk = _getAdmin();
  if (!sdk) return { success: false, error: 'Firebase Admin SDK yüklü değil' };

  try {
    const result = await sdk.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { route: route ?? '', ...data },
      android: {
        notification: {
          channelId: 'finans_asistan_channel',
          priority:   'high',
          color:      '#00D97E',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });
    return { success: true, messageId: result };
  } catch (err) {
    console.error('[FCM] Gönderim hatası:', err.message);
    return { success: false, error: err.message };
  }
}

/**
 * Birden fazla cihaza push gönder (multicast)
 * @param {string[]} tokens
 */
async function sendToMultiple(tokens, payload) {
  const sdk = _getAdmin();
  if (!sdk || tokens.length === 0) return;

  const { title, body, route, data = {} } = payload;
  try {
    await sdk.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { route: route ?? '', ...data },
    });
  } catch (err) {
    console.error('[FCM] Multicast hatası:', err.message);
  }
}

// ── Hazır Bildirim Şablonları ─────────────────────────────────────────────────

async function sendBudgetAlert(fcmToken, { category, spent, limit }) {
  return sendToDevice(fcmToken, {
    title: '⚠️ Bütçe Aşımı',
    body:  `${category} için ${Math.round(spent).toLocaleString('tr-TR')} TL harcandı (limit: ${Math.round(limit).toLocaleString('tr-TR')} TL)`,
    route: '/spending',
    data:  { type: 'budget_alert', category },
  });
}

async function sendMonthlyReport(fcmToken, monthName) {
  return sendToDevice(fcmToken, {
    title: `📊 ${monthName} Raporu Hazır`,
    body:  'AI asistanınız aylık finansal analizinizi tamamladı. Hemen inceleyin.',
    route: '/ai',
    data:  { type: 'monthly_report', month: monthName },
  });
}

async function sendPortfolioAlert(fcmToken, { asset, changePercent }) {
  return sendToDevice(fcmToken, {
    title: changePercent < 0 ? '📉 Portföy Uyarısı' : '📈 Portföy Artışı',
    body:  `${asset}: ${changePercent >= 0 ? '+' : ''}${changePercent.toFixed(2)}%`,
    route: '/portfolio',
    data:  { type: 'portfolio_alert', asset },
  });
}

// ── Token Kaydı (In-Memory, TODO: DB'ye taşı) ─────────────────────────────────
const _tokens = new Map(); // userId → fcmToken

function registerToken(userId, token) {
  _tokens.set(userId, token);
}

function getToken(userId) {
  return _tokens.get(userId);
}

module.exports = {
  sendToDevice, sendToMultiple,
  sendBudgetAlert, sendMonthlyReport, sendPortfolioAlert,
  registerToken, getToken,
};
