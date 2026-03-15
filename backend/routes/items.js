/**
 * Item Routes
 * POST /api/items - Create item (Admin only)
 * GET  /api/items - List items (All authenticated users)
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { createItem, getItems } = require('../controllers/itemController');

router.post('/', auth, requireRole('admin'), createItem);
router.get('/', auth, getItems);  // All roles need items for dropdowns

module.exports = router;
