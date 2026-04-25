'use strict';
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getAuth }      = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

/**
 * Mobil uygulama kullanıcısı kaydolduğunda otomatik olarak 'personal' rolü atar.
 *
 * Tetikleyici: Firestore'da users/{uid} belgesi oluştuğunda.
 *
 * NOT: Firebase Auth onCreate trigger yerine Firestore trigger kullanıyoruz
 * çünkü backend'den oluşturulan merchant hesapları bu fonksiyonu atlayacak
 * (onlar zaten merchant_admin / merchant_cashier rolü alır).
 *
 * Akış:
 *   Flutter app kayıt → Firebase Auth → Flutter, users/{uid} yazar →
 *   Bu function tetiklenir → 'personal' claim set edilir
 */
exports.onUserCreated = onDocumentCreated('users/{uid}', async (event) => {
  const uid  = event.params.uid;
  const data = event.data?.data();

  if (!data) return;

  // Eğer rol backend tarafından zaten set edilmişse dokunma
  if (data.role && data.role !== 'personal') {
    console.log(`[onUserCreated] ${uid} zaten '${data.role}' rolüne sahip, atlanıyor.`);
    return;
  }

  try {
    // 1) Firebase Auth custom claim set et
    await getAuth().setCustomUserClaims(uid, { role: 'personal' });

    // 2) Firestore dokümanına role alanını yaz (yoksa)
    const db = getFirestore();
    await db.collection('users').doc(uid).set(
      { role: 'personal', updatedAt: new Date().toIso8601String?.() ?? new Date().toISOString() },
      { merge: true }
    );

    console.log(`[onUserCreated] ✅ ${uid} → 'personal' rolü atandı.`);
  } catch (err) {
    console.error(`[onUserCreated] ❌ ${uid} rol atama hatası:`, err.message);
  }
});
