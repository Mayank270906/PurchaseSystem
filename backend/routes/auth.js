/**
 * Auth Routes
 * POST /api/auth/login           - Login with username/password
 * POST /api/auth/register        - Self-register (user role only)
 * PUT  /api/auth/change-password  - Change password (authenticated)
 * GET  /api/auth/me              - Get current user (requires auth)
 */

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { login, register, changePassword, getMe } = require('../controllers/authController');

router.post('/login', login);
router.post('/register', register);
router.put('/change-password', auth, changePassword);
router.get('/me', auth, getMe);

module.exports = router;
