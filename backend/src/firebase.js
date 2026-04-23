'use strict';
const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return;

  const base64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (!base64) {
    console.warn('[Firebase] FIREBASE_SERVICE_ACCOUNT_BASE64 tanımlı değil — Admin SDK devre dışı.');
    return;
  }

  try {
    const serviceAccount = JSON.parse(Buffer.from(base64, 'base64').toString('utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    initialized = true;
    console.log('[Firebase] Admin SDK başlatıldı.');
  } catch (e) {
    console.error('[Firebase] Admin SDK başlatma hatası:', e.message);
  }
}

function getFirestore() {
  return initialized ? admin.firestore() : null;
}

function getMessaging() {
  return initialized ? admin.messaging() : null;
}

module.exports = { initFirebase, getFirestore, getMessaging };
