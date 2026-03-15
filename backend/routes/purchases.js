/**
 * Purchase Routes
 * POST /api/purchases - Record purchase (All authenticated users)
 * GET  /api/purchases - List purchases (Manager/Admin only)
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { recordPurchase, getPurchases } = require('../controllers/purchaseController');

// Any authenticated user can record a purchase
router.post('/', auth, recordPurchase);

// Only managers and admins can view purchase history
router.get('/', auth, requireRole('admin', 'manager'), getPurchases);

module.exports = router;
