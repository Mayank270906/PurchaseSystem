/**
 * Dashboard Routes (Manager/Admin)
 * GET /api/dashboard/summary         - Overall financial summary
 * GET /api/dashboard/vendor-balances  - Per-vendor balance breakdown
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { getSummary, getVendorBalances } = require('../controllers/dashboardController');

router.get('/summary', auth, requireRole('admin', 'manager'), getSummary);
router.get('/vendor-balances', auth, requireRole('admin', 'manager'), getVendorBalances);

module.exports = router;
