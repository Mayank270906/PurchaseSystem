/**
 * User Routes (Admin only)
 * POST /api/users - Create user
 * GET  /api/users - List users
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireRole = require('../middleware/role');
const { createUser, getUsers } = require('../controllers/userController');

// All routes require Admin role
router.post('/', auth, requireRole('admin'), createUser);
router.get('/', auth, requireRole('admin'), getUsers);

module.exports = router;
