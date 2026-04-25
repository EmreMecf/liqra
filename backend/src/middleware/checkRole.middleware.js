'use strict';
const admin = require('firebase-admin');

/**
 * Role-based access control (RBAC) middleware
 *
 * Verifies Firebase ID tokens and checks custom claims (role, merchantId).
 * Claims are set server-side via admin.auth().setCustomUserClaims().
 *
 * Usage:
 *   router.get('/admin-only', checkRole('merchant_admin'), handler);
 *   router.post('/staff', checkRole(['merchant_admin', 'merchant_cashier']), handler);
 *
 * req.user is populated with: { id, role, merchantId, token }
 */

function checkRole(allowedRoles) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  return async (req, res, next) => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
          error: 'Yetkisiz erişim — token bulunamadı.',
          code:  'NO_TOKEN',
        });
      }

      const token = authHeader.substring(7);

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(token);
      } catch (err) {
        if (err.code === 'auth/id-token-expired') {
          return res.status(401).json({
            error: 'Token süresi doldu.',
            code:  'TOKEN_EXPIRED',
          });
        }
        return res.status(401).json({
          error: 'Geçersiz token.',
          code:  'INVALID_TOKEN',
        });
      }

      // Custom claims set by admin.auth().setCustomUserClaims()
      const role       = decoded.role       ?? null;
      const merchantId = decoded.merchantId ?? null;

      if (!role) {
        return res.status(403).json({
          error: 'Kullanıcı rolü tanımlanmamış. Yeniden giriş yapın.',
          code:  'NO_ROLE',
        });
      }

      if (!roles.includes(role)) {
        console.warn(`[RBAC] Erişim reddedildi — uid: ${decoded.uid}, rol: ${role}, gerekli: ${roles.join(', ')}`);
        return res.status(403).json({
          error:         `Bu işlemi yapma yetkiniz yok. Gerekli rol: ${roles.join(' veya ')}.`,
          code:          'INSUFFICIENT_ROLE',
          userRole:      role,
          requiredRoles: roles,
        });
      }

      req.user = {
        id:         decoded.uid,
        role,
        merchantId,
        token:      decoded,
      };

      next();
    } catch (err) {
      console.error('[RBAC] Beklenmeyen hata:', err);
      return res.status(500).json({
        error: 'Kimlik doğrulama sırasında bir hata oluştu.',
        code:  'AUTH_ERROR',
      });
    }
  };
}

/**
 * Just verify the Firebase ID token — no role check.
 * Useful for routes that need auth but don't require a specific role.
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token bulunamadı.', code: 'NO_TOKEN' });
  }

  const token = authHeader.substring(7);
  admin.auth().verifyIdToken(token)
    .then(decoded => {
      req.user = {
        id:         decoded.uid,
        role:       decoded.role       ?? null,
        merchantId: decoded.merchantId ?? null,
        token:      decoded,
      };
      next();
    })
    .catch(() => {
      res.status(401).json({ error: 'Geçersiz veya süresi dolmuş token.', code: 'INVALID_TOKEN' });
    });
}

module.exports = { checkRole, verifyToken };
