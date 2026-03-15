/**
 * Purchase Controller
 * 
 * Users record purchases (vendor + item + quantity only).
 * Managers/Admins can view purchase history with filters.
 * 
 * POST /api/purchases - Record a purchase (User, Manager, Admin)
 * GET  /api/purchases - List purchases with filters (Manager/Admin only)
 */

const pool = require('../config/db');

/**
 * Record a new purchase
 * Users only enter vendor, item, and quantity.
 * Date/time is recorded automatically.
 * NO PRICE is stored in this table.
 */
const recordPurchase = async (req, res) => {
    try {
        const { vendor_id, item_id, quantity } = req.body;

        if (!vendor_id || !item_id || !quantity) {
            return res.status(400).json({ error: 'vendor_id, item_id, and quantity are required.' });
        }

        if (quantity <= 0) {
            return res.status(400).json({ error: 'Quantity must be greater than zero.' });
        }

        // Verify vendor exists
        const vendor = await pool.query('SELECT id FROM vendors WHERE id = $1', [vendor_id]);
        if (vendor.rows.length === 0) {
            return res.status(404).json({ error: 'Vendor not found.' });
        }

        // Verify item exists
        const item = await pool.query('SELECT id FROM items WHERE id = $1', [item_id]);
        if (item.rows.length === 0) {
            return res.status(404).json({ error: 'Item not found.' });
        }

        const result = await pool.query(
            `INSERT INTO purchases (vendor_id, item_id, quantity, recorded_by)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
            [vendor_id, item_id, quantity, req.user.id]
        );

        res.status(201).json({
            message: 'Purchase recorded successfully.',
            purchase: result.rows[0]
        });
    } catch (err) {
        console.error('Record purchase error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * Get purchases with filters (Manager/Admin only)
 * Supports filtering by: vendor_id, item_id, date_from, date_to
 * Supports sorting by: datetime, quantity, amount
 * Includes calculated total amount using vendor prices
 */
const getPurchases = async (req, res) => {
    try {
        const { vendor_id, item_id, date_from, date_to, sort_by, sort_order, page, limit } = req.query;

        let query = `
      SELECT p.id, p.vendor_id, v.vendor_name, p.item_id, i.item_name,
             p.quantity, p.datetime, u.username AS recorded_by,
             COALESCE(vip.price, 0) AS unit_price,
             COALESCE(p.quantity * vip.price, 0) AS total_amount
      FROM purchases p
      JOIN vendors v ON v.id = p.vendor_id
      JOIN items i ON i.id = p.item_id
      LEFT JOIN users u ON u.id = p.recorded_by
      LEFT JOIN vendor_item_prices vip ON vip.vendor_id = p.vendor_id AND vip.item_id = p.item_id
      WHERE 1=1
    `;
        const params = [];
        let paramIndex = 1;

        // Apply filters
        if (vendor_id) {
            query += ` AND p.vendor_id = $${paramIndex++}`;
            params.push(vendor_id);
        }
        if (item_id) {
            query += ` AND p.item_id = $${paramIndex++}`;
            params.push(item_id);
        }
        if (date_from) {
            query += ` AND p.datetime >= $${paramIndex++}`;
            params.push(date_from);
        }
        if (date_to) {
            query += ` AND p.datetime <= $${paramIndex++}`;
            params.push(date_to);
        }

        // Apply sorting
        const validSorts = ['datetime', 'quantity', 'total_amount', 'vendor_name'];
        const sortField = validSorts.includes(sort_by) ? sort_by : 'datetime';
        const sortDirection = sort_order === 'asc' ? 'ASC' : 'DESC';
        query += ` ORDER BY ${sortField} ${sortDirection}`;

        // Pagination
        const pageNum = parseInt(page) || 1;
        const pageLimit = Math.min(parseInt(limit) || 50, 100);
        const offset = (pageNum - 1) * pageLimit;
        query += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
        params.push(pageLimit, offset);

        const result = await pool.query(query, params);

        res.json({
            purchases: result.rows,
            pagination: { page: pageNum, limit: pageLimit }
        });
    } catch (err) {
        console.error('Get purchases error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { recordPurchase, getPurchases };
