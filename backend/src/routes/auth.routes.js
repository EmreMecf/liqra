'use strict';
const express = require('express');
const Joi     = require('joi');
const { checkRole } = require('../middleware/checkRole.middleware');
const userService   = require('../services/user.service');

const router = express.Router();

// ── Validasyon şemaları ────────────────────────────────────────────────────────

const merchantOnboardSchema = Joi.object({
  businessName:  Joi.string().min(2).max(100).required(),
  adminEmail:    Joi.string().email().required(),
  adminPassword: Joi.string().min(8).required(),
  adminName:     Joi.string().min(2).max(80).required(),
});

const employeeCreateSchema = Joi.object({
  email:       Joi.string().email().required(),
  password:    Joi.string().min(6).required(),
  displayName: Joi.string().min(2).max(80).required(),
});

// ── Süper Admin Koruma Middleware'i ───────────────────────────────────────────
// Sadece sen (platform sahibi) firma hesabı oluşturabilirsin.
// Header: X-Super-Admin-Key: <SUPER_ADMIN_SECRET>

function requireSuperAdmin(req, res, next) {
  const key = req.headers['x-super-admin-key'];
  if (!key || key !== process.env.SUPER_ADMIN_SECRET) {
    return res.status(403).json({
      error: 'Yetkisiz erişim.',
      code:  'SUPER_ADMIN_REQUIRED',
    });
  }
  next();
}

// ── Validasyon yardımcısı ─────────────────────────────────────────────────────

function validate(schema, body, res) {
  const { error } = schema.validate(body, { abortEarly: false });
  if (error) {
    res.status(400).json({
      error:   'Geçersiz istek verisi.',
      code:    'VALIDATION_ERROR',
      details: error.details.map(d => d.message),
    });
    return false;
  }
  return true;
}

// ═════════════════════════════════════════════════════════════════════════════
// SÜPER ADMİN — Yeni firma (merchant) onboarding
// POST /api/auth/merchant/onboard
// Header: X-Super-Admin-Key: <secret>
//
// Kullanım: Sen bir işletmeye LIQRA POS'u sattığında bu endpoint'i çağırırsın.
// Sonuç: admin Firebase hesabı + Firestore merchant belgesi oluşur.
// ═════════════════════════════════════════════════════════════════════════════
router.post('/merchant/onboard', requireSuperAdmin, async (req, res) => {
  if (!validate(merchantOnboardSchema, req.body, res)) return;

  try {
    const result = await userService.createMerchant(req.body);

    res.status(201).json({
      success: true,
      message: `"${req.body.businessName}" firması başarıyla oluşturuldu.`,
      data:    result,
    });
  } catch (err) {
    // Firebase hataları
    if (err.code === 'auth/email-already-exists') {
      return res.status(409).json({
        error: 'Bu e-posta adresi zaten kullanımda.',
        code:  'EMAIL_IN_USE',
      });
    }
    console.error('[Auth] Merchant onboard hatası:', err.message);
    res.status(500).json({ error: 'Firma oluşturulamadı.', code: 'SERVER_ERROR' });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// MERCHANT ADMİN — Çalışan (kasiyer) oluştur
// POST /api/auth/merchant/employee
// Header: Authorization: Bearer <merchant_admin_jwt>
// ═════════════════════════════════════════════════════════════════════════════
router.post(
  '/merchant/employee',
  checkRole(['merchant_admin']),
  async (req, res) => {
    if (!validate(employeeCreateSchema, req.body, res)) return;

    try {
      const { merchantId } = req.user;   // JWT'den gelir

      if (!merchantId) {
        return res.status(400).json({
          error: 'Firma ID bulunamadı. Token geçersiz olabilir.',
          code:  'MISSING_MERCHANT_ID',
        });
      }

      const employee = await userService.createEmployee({
        merchantId,
        email:       req.body.email,
        password:    req.body.password,
        displayName: req.body.displayName,
      });

      res.status(201).json({
        success: true,
        message: `"${employee.displayName}" çalışanı başarıyla oluşturuldu.`,
        data:    employee,
      });
    } catch (err) {
      if (err.code === 'auth/email-already-exists') {
        return res.status(409).json({
          error: 'Bu e-posta adresi zaten kullanımda.',
          code:  'EMAIL_IN_USE',
        });
      }
      console.error('[Auth] Çalışan oluşturma hatası:', err.message);
      res.status(500).json({ error: 'Çalışan oluşturulamadı.', code: 'SERVER_ERROR' });
    }
  }
);

// ═════════════════════════════════════════════════════════════════════════════
// MERCHANT ADMİN — Çalışanları listele
// GET /api/auth/merchant/employees
// ═════════════════════════════════════════════════════════════════════════════
router.get(
  '/merchant/employees',
  checkRole(['merchant_admin']),
  async (req, res) => {
    try {
      const { merchantId } = req.user;
      const employees = await userService.listEmployees(merchantId);

      res.json({
        success: true,
        data:    employees,
        count:   employees.length,
      });
    } catch (err) {
      console.error('[Auth] Çalışan listesi hatası:', err.message);
      res.status(500).json({ error: 'Çalışanlar alınamadı.', code: 'SERVER_ERROR' });
    }
  }
);

// ═════════════════════════════════════════════════════════════════════════════
// MERCHANT ADMİN — Çalışanı devre dışı bırak
// DELETE /api/auth/merchant/employee/:uid
// ═════════════════════════════════════════════════════════════════════════════
router.delete(
  '/merchant/employee/:uid',
  checkRole(['merchant_admin']),
  async (req, res) => {
    try {
      const { merchantId } = req.user;
      await userService.disableEmployee(req.params.uid, merchantId);

      res.json({
        success: true,
        message: 'Çalışan hesabı devre dışı bırakıldı.',
      });
    } catch (err) {
      if (err.message.includes('firmanıza ait değil')) {
        return res.status(403).json({ error: err.message, code: 'FORBIDDEN' });
      }
      console.error('[Auth] Çalışan devre dışı hatası:', err.message);
      res.status(500).json({ error: 'İşlem başarısız.', code: 'SERVER_ERROR' });
    }
  }
);

// ═════════════════════════════════════════════════════════════════════════════
// HERKESİN ERİŞEBİLECEĞİ — Şifre sıfırlama
// POST /api/auth/password-reset
// Body: { email: "..." }
// ═════════════════════════════════════════════════════════════════════════════
router.post('/password-reset', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'E-posta adresi gereklidir.', code: 'VALIDATION_ERROR' });
  }

  try {
    const result = await userService.sendPasswordResetEmail(email);
    // Production'da link'i gizle, sadece "e-posta gönderildi" de
    res.json({
      success: true,
      message: 'Şifre sıfırlama bağlantısı gönderildi.',
      // Sadece dev'de resetLink göster:
      ...(process.env.NODE_ENV !== 'production' && { resetLink: result.resetLink }),
    });
  } catch (err) {
    // Firebase: user not found hatasını güvenlik nedeniyle ifşa etme
    res.json({
      success: true,
      message: 'Bu e-posta kayıtlıysa şifre sıfırlama bağlantısı gönderildi.',
    });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// MERCHANT ADMİN — Firma bilgisi
// GET /api/auth/merchant/info
// ═════════════════════════════════════════════════════════════════════════════
router.get(
  '/merchant/info',
  checkRole(['merchant_admin', 'merchant_cashier']),
  async (req, res) => {
    try {
      const { merchantId } = req.user;
      const info = await userService.getMerchantInfo(merchantId);

      if (!info) {
        return res.status(404).json({ error: 'Firma bulunamadı.', code: 'NOT_FOUND' });
      }

      res.json({ success: true, data: info });
    } catch (err) {
      console.error('[Auth] Firma bilgisi hatası:', err.message);
      res.status(500).json({ error: 'Bilgi alınamadı.', code: 'SERVER_ERROR' });
    }
  }
);

module.exports = router;
