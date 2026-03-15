/**
 * Item Controller (Admin creates, all roles can read)
 * 
 * POST /api/items - Create item (Admin only)
 * GET  /api/items - List all items (All authenticated users)
 */

const pool = require('../config/db');

/**
 * Create a new item (Admin only)
 */
const createItem = async (req, res) => {
    try {
        const { item_name, description } = req.body;

        if (!item_name) {
            return res.status(400).json({ error: 'Item name is required.' });
        }

        const result = await pool.query(
            `INSERT INTO items (item_name, description)
       VALUES ($1, $2)
       RETURNING *`,
            [item_name, description || null]
        );

        res.status(201).json({
            message: 'Item created successfully.',
            item: result.rows[0]
        });
    } catch (err) {
        console.error('Create item error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * List all items (All authenticated users)
 * Used by users in purchase form dropdowns
 */
const getItems = async (req, res) => {
    try {
        const { search } = req.query;

        let query = 'SELECT * FROM items';
        const params = [];

        // Optional search filter for dropdown
        if (search) {
            query += ' WHERE item_name ILIKE $1';
            params.push(`%${search}%`);
        }

        query += ' ORDER BY item_name ASC';

        const result = await pool.query(query, params);
        res.json({ items: result.rows });
    } catch (err) {
        console.error('Get items error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { createItem, getItems };
