/**
 * Vendor Routes
 * POST   /api/vendors          - Create vendor (Admin)
 * GET    /api/vendors          - List vendors (All authenticated)
 * GET    /api/vendors/:id      - Vendor profile with financials (Manager/Admin)
 * PUT    /api/vendors/:id      - Update vendor (Admin)
 * PUT    /api/vendors/:id/prices - Set item price for vendor (Manager)
 * GET    /api/vendors/:id/prices - Get vendor price list (Manager/Admin)
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { createVendor, getVendors, getVendorProfile, updateVendor } = require('../controllers/vendorController');
const { setPrice, getVendorPrices } = require('../controllers/priceController');

// Vendor CRUD
router.post('/', auth, requireRole('admin'), createVendor);
router.get('/', auth, getVendors);  // All roles need vendors for dropdowns
router.get('/:id', auth, requireRole('admin', 'manager'), getVendorProfile);
router.put('/:id', auth, requireRole('admin'), updateVendor);

// Vendor item prices (nested under vendor)
router.put('/:vendorId/prices', auth, requireRole('manager'), setPrice);
router.get('/:vendorId/prices', auth, requireRole('admin', 'manager'), getVendorPrices);

module.exports = router;
