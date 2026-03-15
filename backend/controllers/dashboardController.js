/**
 * Dashboard Controller (Manager/Admin)
 * 
 * Provides aggregate analytics:
 * - Total purchases across all vendors
 * - Total payments across all vendors
 * - Pending balance (purchases - payments)
 * - Per-vendor breakdown
 * 
 * GET /api/dashboard/summary       - Overall summary
 * GET /api/dashboard/vendor-balances - Per-vendor balances
 */

const pool = require('../config/db');

/**
 * Overall financial summary
 * Returns total purchases, total payments, and pending amount
 */
const getSummary = async (req, res) => {
    try {
        const result = await pool.query(`
      SELECT
        COALESCE(
          (SELECT SUM(p.quantity * COALESCE(vip.price, 0))
           FROM purchases p
           LEFT JOIN vendor_item_prices vip 
             ON vip.vendor_id = p.vendor_id AND vip.item_id = p.item_id
          ), 0
        )::NUMERIC AS total_purchases,
        COALESCE(
          (SELECT SUM(amount) FROM payments), 0
        )::NUMERIC AS total_payments
    `);

        const { total_purchases, total_payments } = result.rows[0];
        const pending_payments = parseFloat(total_purchases) - parseFloat(total_payments);

        res.json({
            total_purchases: parseFloat(total_purchases),
            total_payments: parseFloat(total_payments),
            pending_payments: pending_payments,
            vendor_count: (await pool.query('SELECT COUNT(*) FROM vendors')).rows[0].count,
            item_count: (await pool.query('SELECT COUNT(*) FROM items')).rows[0].count,
            purchase_count: (await pool.query('SELECT COUNT(*) FROM purchases')).rows[0].count,
            payment_count: (await pool.query('SELECT COUNT(*) FROM payments')).rows[0].count
        });
    } catch (err) {
        console.error('Dashboard summary error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * Per-vendor financial breakdown
 * Shows each vendor's total purchases, payments, and pending balance
 */
const getVendorBalances = async (req, res) => {
    try {
        const result = await pool.query(`
      SELECT 
        v.id AS vendor_id,
        v.vendor_name,
        COALESCE(purchase_totals.total, 0)::NUMERIC AS total_purchases,
        COALESCE(payment_totals.total, 0)::NUMERIC AS total_payments,
        (COALESCE(purchase_totals.total, 0) - COALESCE(payment_totals.total, 0))::NUMERIC AS pending_balance
      FROM vendors v
      LEFT JOIN (
        SELECT p.vendor_id, SUM(p.quantity * COALESCE(vip.price, 0)) AS total
        FROM purchases p
        LEFT JOIN vendor_item_prices vip 
          ON vip.vendor_id = p.vendor_id AND vip.item_id = p.item_id
        GROUP BY p.vendor_id
      ) purchase_totals ON purchase_totals.vendor_id = v.id
      LEFT JOIN (
        SELECT vendor_id, SUM(amount) AS total
        FROM payments
        GROUP BY vendor_id
      ) payment_totals ON payment_totals.vendor_id = v.id
      ORDER BY pending_balance DESC
    `);

        res.json({ vendor_balances: result.rows });
    } catch (err) {
        console.error('Vendor balances error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { getSummary, getVendorBalances };
