/**
 * Payment Routes (Manager only)
 * POST /api/payments - Record payment
 * GET  /api/payments - List payments
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { recordPayment, getPayments } = require('../controllers/paymentController');

// Only managers can record and view payments
router.post('/', auth, requireRole('manager'), recordPayment);
router.get('/', auth, requireRole('admin', 'manager'), getPayments);

module.exports = router;
