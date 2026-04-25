'use strict';
const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * Generate JWT token for testing or production
 *
 * @param {string} userId - User ID (Firebase UID or database ID)
 * @param {string} userRole - User role ('personal', 'merchant_admin', 'merchant_cashier')
 * @param {number} expiresIn - Token expiration in seconds (default: 15 minutes)
 * @returns {string} JWT token
 */
function generateToken(userId, userRole = 'personal', expiresIn = '15m') {
  const payload = {
    uid: userId,
    role: userRole,
    iat: Math.floor(Date.now() / 1000)
  };

  return jwt.sign(payload, config.jwt.secret, { expiresIn });
}

/**
 * Generate refresh token
 *
 * @param {string} userId - User ID
 * @returns {string} Refresh token (7 days expiry)
 */
function generateRefreshToken(userId) {
  const payload = {
    uid: userId,
    type: 'refresh',
    iat: Math.floor(Date.now() / 1000)
  };

  return jwt.sign(payload, config.jwt.secret, { expiresIn: '7d' });
}

/**
 * Verify token
 *
 * @param {string} token - JWT token to verify
 * @returns {object|null} Decoded token or null if invalid
 */
function verifyToken(token) {
  try {
    return jwt.verify(token, config.jwt.secret);
  } catch (err) {
    return null;
  }
}

/**
 * Generate test tokens for different roles
 * ONLY FOR TESTING AND DEVELOPMENT
 *
 * Usage:
 *   const tokens = generateTestTokens('test-user-123');
 *   console.log(tokens.merchant_admin); // Use this token in requests
 */
function generateTestTokens(userId) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Test tokens cannot be generated in production environment');
  }

  return {
    personal: generateToken(userId, 'personal'),
    merchant_admin: generateToken(userId, 'merchant_admin'),
    merchant_cashier: generateToken(userId, 'merchant_cashier'),
    invalid: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.invalid'
  };
}

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  generateTestTokens
};
