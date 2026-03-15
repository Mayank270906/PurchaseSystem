/**
 * User Controller (Admin only)
 * 
 * Handles user creation and listing.
 * POST /api/users - Create a new user with role
 * GET  /api/users - List all users
 */

const bcrypt = require('bcryptjs');
const pool = require('../config/db');

/**
 * Create a new user (Admin only)
 * Hashes password and assigns role
 */
const createUser = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;

        // Validate required fields
        if (!username || !email || !password || !role) {
            return res.status(400).json({
                error: 'All fields required: username, email, password, role.'
            });
        }

        // Validate role
        const validRoles = ['manager', 'user'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({
                error: 'Role must be either "manager" or "user".'
            });
        }

        // Check if username or email already exists
        const existing = await pool.query(
            'SELECT id FROM users WHERE username = $1 OR email = $2',
            [username, email]
        );
        if (existing.rows.length > 0) {
            return res.status(409).json({ error: 'Username or email already exists.' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Insert user
        const result = await pool.query(
            `INSERT INTO users (username, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, email, role, created_at`,
            [username, email, password_hash, role]
        );

        res.status(201).json({
            message: 'User created successfully.',
            user: result.rows[0]
        });
    } catch (err) {
        console.error('Create user error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * List all users (Admin only)
 * Returns users without password hashes
 */
const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC'
        );
        res.json({ users: result.rows });
    } catch (err) {
        console.error('Get users error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { createUser, getUsers };
