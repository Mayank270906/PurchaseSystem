/**
 * Vendor Controller
 * 
 * Admin can create/edit vendors.
 * All users can list vendors (for purchase dropdowns).
 * Manager/Admin can view full vendor profiles with financial data.
 * 
 * POST   /api/vendors          - Create vendor (Admin)
 * GET    /api/vendors          - List vendors (All authenticated)
 * GET    /api/vendors/:id      - Get vendor profile with financials (Manager/Admin)
 * PUT    /api/vendors/:id      - Update vendor (Admin)
 */

const pool = require('../config/db');

/**
 * Create a new vendor (Admin only)
 */
const createVendor = async (req, res) => {
    try {
        const { vendor_name, phone, address, notes } = req.body;

        if (!vendor_name) {
            return res.status(400).json({ error: 'Vendor name is required.' });
        }

        const result = await pool.query(
            `INSERT INTO vendors (vendor_name, phone, address, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
            [vendor_name, phone || null, address || null, notes || null]
        );

        res.status(201).json({
            message: 'Vendor created successfully.',
            vendor: result.rows[0]
        });
    } catch (err) {
        console.error('Create vendor error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * List all vendors (All authenticated users)
 * Users need this for purchase form dropdown
 */
const getVendors = async (req, res) => {
    try {
        const { search } = req.query;

        let query = 'SELECT id, vendor_name, phone, address FROM vendors';
        const params = [];

        if (search) {
            query += ' WHERE vendor_name ILIKE $1';
            params.push(`%${search}%`);
        }

        query += ' ORDER BY vendor_name ASC';

        const result = await pool.query(query, params);
        res.json({ vendors: result.rows });
    } catch (err) {
        console.error('Get vendors error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * Get vendor full profile with financial summary (Manager/Admin)
 * Includes: info, price list, purchase history, payment history, balance
 */
const getVendorProfile = async (req, res) => {
    try {
        const { id } = req.params;

        // Vendor basic info
        const vendorResult = await pool.query(
            'SELECT * FROM vendors WHERE id = $1', [id]
        );
        if (vendorResult.rows.length === 0) {
            return res.status(404).json({ error: 'Vendor not found.' });
        }

        // Price list for this vendor
        const pricesResult = await pool.query(
            `SELECT vip.id, vip.item_id, i.item_name, vip.price, 
              vip.updated_at, u.username AS updated_by
       FROM vendor_item_prices vip
       JOIN items i ON i.id = vip.item_id
       LEFT JOIN users u ON u.id = vip.updated_by
       WHERE vip.vendor_id = $1
       ORDER BY i.item_name ASC`,
            [id]
        );

        // Purchase history (with calculated amounts using vendor prices)
        const purchasesResult = await pool.query(
            `SELECT p.id, p.item_id, i.item_name, p.quantity, p.datetime,
              u.username AS recorded_by,
              COALESCE(vip.price, 0) AS unit_price,
              COALESCE(p.quantity * vip.price, 0) AS total_amount
       FROM purchases p
       JOIN items i ON i.id = p.item_id
       LEFT JOIN users u ON u.id = p.recorded_by
       LEFT JOIN vendor_item_prices vip ON vip.vendor_id = p.vendor_id AND vip.item_id = p.item_id
       WHERE p.vendor_id = $1
       ORDER BY p.datetime DESC`,
            [id]
        );

        // Payment history
        const paymentsResult = await pool.query(
            `SELECT pay.id, pay.amount, pay.purpose, pay.payment_method, 
              pay.datetime, pay.notes, u.username AS recorded_by
       FROM payments pay
       LEFT JOIN users u ON u.id = pay.recorded_by
       WHERE pay.vendor_id = $1
       ORDER BY pay.datetime DESC`,
            [id]
        );

        // Financial summary
        const summaryResult = await pool.query(
            `SELECT
        COALESCE(
          (SELECT SUM(p.quantity * COALESCE(vip.price, 0))
           FROM purchases p
           LEFT JOIN vendor_item_prices vip ON vip.vendor_id = p.vendor_id AND vip.item_id = p.item_id
           WHERE p.vendor_id = $1), 0
        ) AS total_purchases,
        COALESCE(
          (SELECT SUM(pay.amount) FROM payments pay WHERE pay.vendor_id = $1), 0
        ) AS total_payments`,
            [id]
        );

        const summary = summaryResult.rows[0];
        const pending_balance = parseFloat(summary.total_purchases) - parseFloat(summary.total_payments);

        res.json({
            vendor: vendorResult.rows[0],
            price_list: pricesResult.rows,
            purchases: purchasesResult.rows,
            payments: paymentsResult.rows,
            financial_summary: {
                total_purchases: parseFloat(summary.total_purchases),
                total_payments: parseFloat(summary.total_payments),
                pending_balance: pending_balance
            }
        });
    } catch (err) {
        console.error('Get vendor profile error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * Update vendor info (Admin only)
 */
const updateVendor = async (req, res) => {
    try {
        const { id } = req.params;
        const { vendor_name, phone, address, notes } = req.body;

        const result = await pool.query(
            `UPDATE vendors 
       SET vendor_name = COALESCE($1, vendor_name),
           phone = COALESCE($2, phone),
           address = COALESCE($3, address),
           notes = COALESCE($4, notes)
       WHERE id = $5
       RETURNING *`,
            [vendor_name, phone, address, notes, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Vendor not found.' });
        }

        res.json({
            message: 'Vendor updated successfully.',
            vendor: result.rows[0]
        });
    } catch (err) {
        console.error('Update vendor error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { createVendor, getVendors, getVendorProfile, updateVendor };
