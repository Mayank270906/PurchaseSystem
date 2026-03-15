/**
 * Payment Controller (Manager only)
 * 
 * Managers record and view payments made to vendors.
 * 
 * POST /api/payments - Record a payment (Manager only)
 * GET  /api/payments - List payments with filters (Manager/Admin)
 */

const pool = require('../config/db');

/**
 * Record a new payment to a vendor
 */
const recordPayment = async (req, res) => {
    try {
        const { vendor_id, amount, purpose, payment_method, notes } = req.body;

        if (!vendor_id || !amount) {
            return res.status(400).json({ error: 'vendor_id and amount are required.' });
        }

        if (amount <= 0) {
            return res.status(400).json({ error: 'Amount must be greater than zero.' });
        }

        // Verify vendor exists
        const vendor = await pool.query('SELECT id FROM vendors WHERE id = $1', [vendor_id]);
        if (vendor.rows.length === 0) {
            return res.status(404).json({ error: 'Vendor not found.' });
        }

        const result = await pool.query(
            `INSERT INTO payments (vendor_id, amount, purpose, payment_method, recorded_by, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
            [vendor_id, amount, purpose || null, payment_method || null, req.user.id, notes || null]
        );

        res.status(201).json({
            message: 'Payment recorded successfully.',
            payment: result.rows[0]
        });
    } catch (err) {
        console.error('Record payment error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * List payments with optional filtering
 * Supports: vendor_id, date_from, date_to, pagination
 */
const getPayments = async (req, res) => {
    try {
        const { vendor_id, date_from, date_to, page, limit } = req.query;

        let query = `
      SELECT pay.id, pay.vendor_id, v.vendor_name, pay.amount, 
             pay.purpose, pay.payment_method, pay.datetime, 
             pay.notes, u.username AS recorded_by
      FROM payments pay
      JOIN vendors v ON v.id = pay.vendor_id
      LEFT JOIN users u ON u.id = pay.recorded_by
      WHERE 1=1
    `;
        const params = [];
        let paramIndex = 1;

        if (vendor_id) {
            query += ` AND pay.vendor_id = $${paramIndex++}`;
            params.push(vendor_id);
        }
        if (date_from) {
            query += ` AND pay.datetime >= $${paramIndex++}`;
            params.push(date_from);
        }
        if (date_to) {
            query += ` AND pay.datetime <= $${paramIndex++}`;
            params.push(date_to);
        }

        query += ` ORDER BY pay.datetime DESC`;

        // Pagination
        const pageNum = parseInt(page) || 1;
        const pageLimit = Math.min(parseInt(limit) || 50, 100);
        const offset = (pageNum - 1) * pageLimit;
        query += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
        params.push(pageLimit, offset);

        const result = await pool.query(query, params);

        res.json({
            payments: result.rows,
            pagination: { page: pageNum, limit: pageLimit }
        });
    } catch (err) {
        console.error('Get payments error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { recordPayment, getPayments };
