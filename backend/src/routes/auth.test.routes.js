'use strict';
const express = require('express');
const config = require('../config');
const { generateTestTokens } = require('../utils/jwt.utils');

const router = express.Router();

/**
 * TEST ROUTES — Development only
 *
 * WARNING: These routes must be disabled in production!
 * They are used for testing RBAC middleware and role-based access control.
 */

if (process.env.NODE_ENV !== 'production') {
  /**
   * POST /api/auth/test/tokens/:userId
   * Generate test JWT tokens for different roles
   *
   * Usage:
   *   POST /api/auth/test/tokens/test-user-123
   *   Returns: {personal, merchant_admin, merchant_cashier, invalid}
   *
   * Example response:
   *   {
   *     user_id: "test-user-123",
   *     tokens: {
   *       personal: "eyJhbGc...",
   *       merchant_admin: "eyJhbGc...",
   *       merchant_cashier: "eyJhbGc...",
   *       invalid: "invalid_token"
   *     },
   *     message: "Test tokens generated. Use in Authorization header: Bearer {token}"
   *   }
   */
  router.post('/test/tokens/:userId', (req, res) => {
    try {
      const { userId } = req.params;

      if (!userId || userId.length < 3) {
        return res.status(400).json({
          error: 'Invalid user ID. Must be at least 3 characters.',
          code: 'INVALID_USER_ID'
        });
      }

      const tokens = generateTestTokens(userId);

      res.json({
        user_id: userId,
        tokens,
        message:
          'Test tokens generated. Use in Authorization header: Authorization: Bearer {token}',
        note: '⚠️ These tokens expire in 15 minutes. Use invalid token for 403 testing.',
        example_usage: {
          merchant_admin: `curl -H "Authorization: Bearer ${tokens.merchant_admin}" http://localhost:3000/api/merchant/dashboard`,
          merchant_cashier: `curl -H "Authorization: Bearer ${tokens.merchant_cashier}" http://localhost:3000/api/merchant/transaction`,
          invalid_token: `curl -H "Authorization: Bearer ${tokens.invalid}" http://localhost:3000/api/merchant/dashboard`
        }
      });
    } catch (err) {
      res.status(500).json({
        error: err.message,
        code: 'TOKEN_GENERATION_ERROR'
      });
    }
  });

  /**
   * GET /api/auth/test/info
   * Get information about test endpoints
   */
  router.get('/test/info', (req, res) => {
    res.json({
      environment: process.env.NODE_ENV,
      message: 'Test endpoints are available in development mode.',
      available_endpoints: [
        {
          method: 'POST',
          path: '/api/auth/test/tokens/:userId',
          description: 'Generate test JWT tokens for different roles'
        },
        {
          method: 'GET',
          path: '/api/merchant/dashboard',
          requires: 'merchant_admin role',
          example: 'First generate tokens, then use merchant_admin token'
        },
        {
          method: 'GET',
          path: '/api/merchant/reports',
          requires: 'merchant_admin role'
        },
        {
          method: 'GET',
          path: '/api/merchant/staff',
          requires: 'merchant_admin role'
        },
        {
          method: 'POST',
          path: '/api/merchant/transaction',
          requires: 'merchant_admin or merchant_cashier role'
        },
        {
          method: 'GET',
          path: '/api/merchant/transactions',
          requires: 'merchant_admin or merchant_cashier role'
        }
      ],
      testing_guide: {
        step1: 'Generate test tokens: POST /api/auth/test/tokens/test-user-123',
        step2: 'Copy merchant_admin token from response',
        step3: 'Access protected route with header: Authorization: Bearer {token}',
        step4: 'Try merchant_cashier token on merchant_admin-only routes (should get 403)',
        step5: 'Try invalid token (should get 401)'
      }
    });
  });

  /**
   * GET /api/auth/test/rbac-demo
   * Interactive RBAC testing demonstration
   */
  router.get('/test/rbac-demo', (req, res) => {
    const demoUserId = 'demo-user-' + Date.now();
    const tokens = generateTestTokens(demoUserId);

    res.json({
      demo_user_id: demoUserId,
      instructions:
        'Copy tokens below and make requests to /api/merchant/* endpoints',

      // ─── TEST CASE 1: merchant_admin access ───
      test_case_1: {
        name: 'merchant_admin Access (Should succeed)',
        role: 'merchant_admin',
        token: tokens.merchant_admin,
        endpoints_to_test: [
          {
            method: 'GET',
            path: '/api/merchant/dashboard',
            expected_status: 200,
            curl: `curl -H "Authorization: Bearer ${tokens.merchant_admin}" http://localhost:3000/api/merchant/dashboard`
          },
          {
            method: 'GET',
            path: '/api/merchant/reports',
            expected_status: 200
          },
          {
            method: 'GET',
            path: '/api/merchant/staff',
            expected_status: 200
          }
        ]
      },

      // ─── TEST CASE 2: merchant_cashier access ───
      test_case_2: {
        name: 'merchant_cashier Access (Limited)',
        role: 'merchant_cashier',
        token: tokens.merchant_cashier,
        endpoints_to_test: [
          {
            method: 'GET',
            path: '/api/merchant/dashboard',
            expected_status: 403,
            reason: 'Cashiers cannot access admin dashboard',
            curl: `curl -H "Authorization: Bearer ${tokens.merchant_cashier}" http://localhost:3000/api/merchant/dashboard`
          },
          {
            method: 'POST',
            path: '/api/merchant/transaction',
            expected_status: 201,
            reason: 'Cashiers can create transactions',
            body: {
              amount: 250.0,
              payment_method: 'cash',
              items: [{ name: 'Kahve', quantity: 1, price: 50.0 }]
            }
          },
          {
            method: 'GET',
            path: '/api/merchant/transactions',
            expected_status: 200,
            reason: 'Cashiers can view transactions'
          }
        ]
      },

      // ─── TEST CASE 3: No token ───
      test_case_3: {
        name: 'No Token (Should fail)',
        expected_status: 401,
        endpoints_to_test: [
          {
            method: 'GET',
            path: '/api/merchant/dashboard',
            curl: 'curl http://localhost:3000/api/merchant/dashboard'
          }
        ]
      },

      // ─── TEST CASE 4: Invalid token ───
      test_case_4: {
        name: 'Invalid Token (Should fail)',
        token: tokens.invalid,
        expected_status: 401,
        curl: `curl -H "Authorization: Bearer ${tokens.invalid}" http://localhost:3000/api/merchant/dashboard`
      }
    });
  });
} else {
  // In production, return 404 for test routes
  router.all('/test/*', (req, res) => {
    res.status(404).json({
      error: 'Test routes are not available in production.'
    });
  });
}

module.exports = router;
