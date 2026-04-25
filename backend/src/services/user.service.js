'use strict';
const admin    = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { getFirestore } = require('../firebase');

/**
 * Kullanıcı yönetim servisi
 *
 * Sorumluluklar:
 *   - Firma (merchant) onboarding → admin hesabı oluşturma
 *   - Çalışan hesabı oluşturma (merchant_admin tarafından)
 *   - Firebase Auth custom claims yönetimi
 *   - Firestore'da kullanıcı verisi saklama
 */

// ── Merchant Onboarding ────────────────────────────────────────────────────────
// Sen (platform sahibi) her yeni firma sattığında bu fonksiyonu çağırırsın.
// Sonuç: admin Firebase Auth hesabı + Firestore merchant belgesi.

async function createMerchant({ businessName, adminEmail, adminPassword, adminName }) {
  const db         = getFirestore();
  const merchantId = `merchant_${uuidv4().replace(/-/g, '').slice(0, 12)}`;

  // 1) Firebase Auth kullanıcı oluştur
  const userRecord = await admin.auth().createUser({
    email:        adminEmail,
    password:     adminPassword,
    displayName:  adminName,
    emailVerified: false,
  });

  const uid = userRecord.uid;

  // 2) Custom claim set et — JWT'ye role + merchantId gömülür
  await admin.auth().setCustomUserClaims(uid, {
    role:       'merchant_admin',
    merchantId,
  });

  // 3) Firestore: merchants koleksiyonu
  await db.collection('merchants').doc(merchantId).set({
    merchantId,
    businessName,
    adminUid:  uid,
    adminName,
    adminEmail,
    active:    true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    plan:      'starter',          // ileride plan yönetimi için
    employeeCount: 0,
  });

  // 4) Firestore: users koleksiyonu
  await db.collection('users').doc(uid).set({
    uid,
    email:       adminEmail,
    displayName: adminName,
    role:        'merchant_admin',
    merchantId,
    createdAt:   admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[UserService] ✅ Merchant oluşturuldu: ${businessName} (${merchantId})`);

  return {
    merchantId,
    admin: {
      uid,
      email:       adminEmail,
      displayName: adminName,
      role:        'merchant_admin',
    },
  };
}

// ── Çalışan Oluşturma ─────────────────────────────────────────────────────────
// Merchant admin, kendi çalışanını (kasiyer) oluşturur.

async function createEmployee({ merchantId, email, password, displayName }) {
  const db = getFirestore();

  // Firmanın var olup olmadığını doğrula
  const merchantSnap = await db.collection('merchants').doc(merchantId).get();
  if (!merchantSnap.exists) {
    throw new Error(`Firma bulunamadı: ${merchantId}`);
  }

  // 1) Firebase Auth kullanıcı oluştur
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName,
    emailVerified: false,
  });

  const uid = userRecord.uid;

  // 2) Custom claim set et
  await admin.auth().setCustomUserClaims(uid, {
    role:       'merchant_cashier',
    merchantId,
  });

  // 3) Firestore: users
  await db.collection('users').doc(uid).set({
    uid,
    email,
    displayName,
    role:       'merchant_cashier',
    merchantId,
    createdAt:  admin.firestore.FieldValue.serverTimestamp(),
  });

  // 4) merchant'ın employeeCount'unu artır
  await db.collection('merchants').doc(merchantId).update({
    employeeCount: admin.firestore.FieldValue.increment(1),
  });

  console.log(`[UserService] ✅ Çalışan oluşturuldu: ${displayName} → ${merchantId}`);

  return {
    uid,
    email,
    displayName,
    role:       'merchant_cashier',
    merchantId,
  };
}

// ── Çalışanları Listele ────────────────────────────────────────────────────────

async function listEmployees(merchantId) {
  const db = getFirestore();
  const snap = await db.collection('users')
    .where('merchantId', '==', merchantId)
    .where('role', '==', 'merchant_cashier')
    .orderBy('createdAt', 'asc')
    .get();

  return snap.docs.map(doc => {
    const d = doc.data();
    return {
      uid:         d.uid,
      email:       d.email,
      displayName: d.displayName,
      role:        d.role,
      createdAt:   d.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  });
}

// ── Çalışan Sil / Devre Dışı Bırak ────────────────────────────────────────────

async function disableEmployee(uid, merchantId) {
  const db = getFirestore();

  // Kullanıcının bu merchant'a ait olduğunu doğrula
  const userSnap = await db.collection('users').doc(uid).get();
  const data = userSnap.data();

  if (!data || data.merchantId !== merchantId) {
    throw new Error('Bu çalışan firmanıza ait değil.');
  }

  if (data.role !== 'merchant_cashier') {
    throw new Error('Sadece kasiyer hesapları devre dışı bırakılabilir.');
  }

  // Firebase Auth'ta disable et (silmek yerine devre dışı bırak — veri korunur)
  await admin.auth().updateUser(uid, { disabled: true });

  // Firestore'da işaretle
  await db.collection('users').doc(uid).update({ active: false });

  // Merchant employee sayısını azalt
  await db.collection('merchants').doc(merchantId).update({
    employeeCount: admin.firestore.FieldValue.increment(-1),
  });

  console.log(`[UserService] ⛔ Çalışan devre dışı: ${uid}`);
  return { success: true };
}

// ── Şifre Sıfırlama Linki ─────────────────────────────────────────────────────

async function sendPasswordResetEmail(email) {
  const link = await admin.auth().generatePasswordResetLink(email);
  // Kendi e-posta servisinle gönderebilirsin.
  // Şimdilik linki döndürüyoruz; production'da gizle.
  return { resetLink: link };
}

// ── Merchant Bilgisi ──────────────────────────────────────────────────────────

async function getMerchantInfo(merchantId) {
  const db   = getFirestore();
  const snap = await db.collection('merchants').doc(merchantId).get();
  if (!snap.exists) return null;

  const d = snap.data();
  return {
    merchantId:    d.merchantId,
    businessName:  d.businessName,
    adminEmail:    d.adminEmail,
    active:        d.active,
    plan:          d.plan,
    employeeCount: d.employeeCount,
    createdAt:     d.createdAt?.toDate?.()?.toISOString() ?? null,
  };
}

module.exports = {
  createMerchant,
  createEmployee,
  listEmployees,
  disableEmployee,
  sendPasswordResetEmail,
  getMerchantInfo,
};
