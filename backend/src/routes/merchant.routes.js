'use strict';
const express = require('express');
const Joi = require('joi');
const { checkRole, verifyToken } = require('../middleware/checkRole.middleware');
const config = require('../config');

const router = express.Router();

/**
 * Merchant routes — role-protected endpoints
 *
 * Roles:
 * - merchant_admin: Full access to all merchant operations
 * - merchant_cashier: Limited access (transactions only)
 */

// ──────────────────────────────────────────────────────────────────────────────
// MERCHANT DASHBOARD — merchant_admin ONLY
// ──────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/merchant/dashboard
 * Returns merchant's main dashboard data (admin only)
 *
 * @requires merchant_admin role
 * @returns {200} Dashboard data with sales, revenue, stats
 * @returns {403} User doesn't have merchant_admin role
 * @returns {401} No token or invalid token
 */
router.get('/dashboard', checkRole('merchant_admin'), async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`[Merchant Dashboard] Accessing user: ${userId}, role: ${userRole}`);

    // TODO: Fetch real merchant data from database
    // - Sales summary (today, week, month)
    // - Revenue metrics
    // - Transaction history
    // - Staff activity

    const dashboardData = {
      merchant_id: userId,
      merchant_name: 'Örnek Esnaf İşletmesi',
      role: userRole,
      stats: {
        today_sales: 15420.75,
        today_transactions: 43,
        week_revenue: 102340.50,
        month_revenue: 456789.20,
        average_transaction: 357.84,
        customer_count: 2341
      },
      recent_transactions: [
        {
          id: 'txn_001',
          amount: 250.00,
          timestamp: new Date().toISOString(),
          payment_method: 'credit_card',
          status: 'completed'
        },
        {
          id: 'txn_002',
          amount: 125.50,
          timestamp: new Date().toISOString(),
          payment_method: 'cash',
          status: 'completed'
        }
      ],
      staff_summary: {
        total_staff: 5,
        active_now: 2,
        cashiers: 3,
        supervisors: 1
      },
      alerts: [
        {
          type: 'info',
          message: 'Yeni kasiyer onay bekliyor',
          timestamp: new Date().toISOString()
        }
      ]
    };

    res.json({
      success: true,
      data: dashboardData,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('[Merchant Dashboard] Error:', err);
    res.status(500).json({
      error: 'Dashboard verilerine erişilemiyor.',
      code: 'DASHBOARD_ERROR'
    });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// MERCHANT REPORTS — merchant_admin ONLY
// ──────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/merchant/reports
 * Returns detailed merchant reports (admin only)
 *
 * @requires merchant_admin role
 * @query {string} period - 'daily' | 'weekly' | 'monthly' | 'custom'
 * @query {string} start_date - YYYY-MM-DD (for custom period)
 * @query {string} end_date - YYYY-MM-DD (for custom period)
 */
router.get('/reports', checkRole('merchant_admin'), async (req, res) => {
  try {
    const { period = 'monthly' } = req.query;
    const userId = req.user.id;

    // Validate period
    const validPeriods = ['daily', 'weekly', 'monthly', 'yearly'];
    if (!validPeriods.includes(period)) {
      return res.status(400).json({
        error: 'Geçersiz dönem. daily, weekly, monthly veya yearly olmalı.',
        code: 'INVALID_PERIOD'
      });
    }

    // TODO: Generate reports from database
    const reportData = {
      merchant_id: userId,
      period,
      generated_at: new Date().toISOString(),
      summary: {
        total_revenue: 456789.20,
        total_transactions: 1240,
        average_transaction: 368.37,
        total_refunds: 12340.50,
        refund_rate: 2.7
      },
      breakdown_by_category: {
        'Yiyecek': 245600.00,
        'İçecek': 89500.00,
        'Diğer': 121689.20
      },
      top_items: [
        { name: 'Kahve', quantity: 450, revenue: 67500 },
        { name: 'Sandviç', quantity: 380, revenue: 95000 },
        { name: 'Tatlı', quantity: 200, revenue: 45000 }
      ]
    };

    res.json({
      success: true,
      data: reportData
    });
  } catch (err) {
    console.error('[Merchant Reports] Error:', err);
    res.status(500).json({
      error: 'Raporlar oluşturulamıyor.',
      code: 'REPORTS_ERROR'
    });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// MERCHANT STAFF MANAGEMENT — merchant_admin ONLY
// ──────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/merchant/staff
 * Lists all staff members (admin only)
 *
 * @requires merchant_admin role
 */
router.get('/staff', checkRole('merchant_admin'), async (req, res) => {
  try {
    const userId = req.user.id;

    // TODO: Fetch actual staff data
    const staffList = [
      {
        id: 'staff_001',
        name: 'Ahmet Yılmaz',
        role: 'merchant_cashier',
        status: 'active',
        hire_date: '2023-01-15'
      },
      {
        id: 'staff_002',
        name: 'Fatma Demir',
        role: 'merchant_cashier',
        status: 'active',
        hire_date: '2023-03-20'
      }
    ];

    res.json({
      success: true,
      data: staffList,
      total: staffList.length
    });
  } catch (err) {
    console.error('[Staff List] Error:', err);
    res.status(500).json({
      error: 'Personel listesi alınamıyor.',
      code: 'STAFF_LIST_ERROR'
    });
  }
});

/**
 * POST /api/merchant/staff/:staffId/role
 * Update staff member's role (admin only)
 *
 * @requires merchant_admin role
 * @body {string} role - 'merchant_cashier' | 'merchant_supervisor'
 */
router.post('/staff/:staffId/role', checkRole('merchant_admin'), async (req, res) => {
  try {
    const { staffId } = req.params;
    const { role } = req.body;
    const adminId = req.user.id;

    // Validate role
    const validRoles = ['merchant_cashier', 'merchant_supervisor'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        error: 'Geçersiz rol.',
        code: 'INVALID_ROLE'
      });
    }

    // TODO: Update staff role in database
    console.log(`[Staff Role] Admin ${adminId} updating staff ${staffId} to ${role}`);

    res.json({
      success: true,
      message: `Personel rolü ${role} olarak güncellendi.`,
      data: {
        staff_id: staffId,
        new_role: role,
        updated_at: new Date().toISOString()
      }
    });
  } catch (err) {
    console.error('[Staff Role Update] Error:', err);
    res.status(500).json({
      error: 'Rol güncellenemedi.',
      code: 'ROLE_UPDATE_ERROR'
    });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// MERCHANT CASHIER OPERATIONS — merchant_admin OR merchant_cashier
// ──────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/merchant/transaction
 * Create a new sale transaction
 *
 * @requires merchant_admin | merchant_cashier role
 * @body {number} amount - Sale amount in TL
 * @body {string} payment_method - 'cash' | 'credit_card' | 'debit_card'
 * @body {Array} items - Items in transaction
 */
router.post(
  '/transaction',
  checkRole(['merchant_admin', 'merchant_cashier']),
  async (req, res) => {
    try {
      const { amount, payment_method, items } = req.body;
      const userId = req.user.id;
      const userRole = req.user.role;

      // Validation
      const schema = Joi.object({
        amount: Joi.number().positive().required(),
        payment_method: Joi.string()
          .valid('cash', 'credit_card', 'debit_card')
          .required(),
        items: Joi.array()
          .items(
            Joi.object({
              name: Joi.string().required(),
              quantity: Joi.number().positive().required(),
              price: Joi.number().positive().required()
            })
          )
          .min(1)
          .required()
      });

      const { error, value } = schema.validate(req.body);
      if (error) {
        return res.status(400).json({
          error: error.details[0].message,
          code: 'VALIDATION_ERROR'
        });
      }

      // TODO: Create transaction in database
      const transactionId = `txn_${Date.now()}`;

      res.status(201).json({
        success: true,
        message: 'İşlem başarıyla oluşturuldu.',
        data: {
          transaction_id: transactionId,
          amount: value.amount,
          payment_method: value.payment_method,
          items: value.items,
          cashier: userId,
          cashier_role: userRole,
          timestamp: new Date().toISOString(),
          status: 'completed'
        }
      });
    } catch (err) {
      console.error('[Create Transaction] Error:', err);
      res.status(500).json({
        error: 'İşlem oluşturulamadı.',
        code: 'TRANSACTION_ERROR'
      });
    }
  }
);

/**
 * GET /api/merchant/transactions
 * List transactions (admin sees all, cashier sees own)
 *
 * @requires merchant_admin | merchant_cashier role
 */
router.get('/transactions', checkRole(['merchant_admin', 'merchant_cashier']), async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    // TODO: Fetch transactions based on role
    // If merchant_admin: all transactions
    // If merchant_cashier: only transactions created by this cashier

    const transactions = [
      {
        id: 'txn_001',
        amount: 250.00,
        payment_method: 'cash',
        cashier_id: userId,
        timestamp: new Date().toISOString(),
        status: 'completed'
      }
    ];

    res.json({
      success: true,
      data: transactions,
      total: transactions.length,
      filtered_by_role: userRole
    });
  } catch (err) {
    console.error('[List Transactions] Error:', err);
    res.status(500).json({
      error: 'İşlemler alınamıyor.',
      code: 'TRANSACTIONS_LIST_ERROR'
    });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// SETTINGS — merchant_admin ONLY
// ──────────────────────────────────────────────────────────────────────────────

/**
 * PUT /api/merchant/settings
 * Update merchant settings (admin only)
 *
 * @requires merchant_admin role
 */
router.put('/settings', checkRole('merchant_admin'), async (req, res) => {
  try {
    const { business_name, address, phone, email } = req.body;
    const adminId = req.user.id;

    // Validation
    const schema = Joi.object({
      business_name: Joi.string().max(100),
      address: Joi.string().max(255),
      phone: Joi.string().max(20),
      email: Joi.string().email()
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // TODO: Update merchant settings in database
    console.log(`[Merchant Settings] Admin ${adminId} updating settings`, value);

    res.json({
      success: true,
      message: 'Ayarlar güncellendi.',
      data: value
    });
  } catch (err) {
    console.error('[Update Settings] Error:', err);
    res.status(500).json({
      error: 'Ayarlar güncellenemedi.',
      code: 'SETTINGS_ERROR'
    });
  }
});

module.exports = router;
