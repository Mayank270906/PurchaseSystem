/**
 * Vendor Item Price Controller (Manager)
 * 
 * Managers set and update item prices for each vendor.
 * Prices vary by vendor — same item can have different prices.
 * 
 * PUT  /api/vendors/:vendorId/prices - Set/update price (Manager)
 * GET  /api/vendors/:vendorId/prices - Get vendor's price list (Manager/Admin)
 */

const pool = require('../config/db');

/**
 * Set or update an item's price for a specific vendor
 * Uses UPSERT (INSERT ... ON CONFLICT UPDATE)
 */
const setPrice = async (req, res) => {
    try {
        const { vendorId } = req.params;
        const { item_id, price } = req.body;

        if (!item_id || price === undefined || price === null) {
            return res.status(400).json({ error: 'item_id and price are required.' });
        }

        if (price < 0) {
            return res.status(400).json({ error: 'Price must be non-negative.' });
        }

        // Verify vendor exists
        const vendor = await pool.query('SELECT id FROM vendors WHERE id = $1', [vendorId]);
        if (vendor.rows.length === 0) {
            return res.status(404).json({ error: 'Vendor not found.' });
        }

        // Verify item exists
        const item = await pool.query('SELECT id FROM items WHERE id = $1', [item_id]);
        if (item.rows.length === 0) {
            return res.status(404).json({ error: 'Item not found.' });
        }

        // Upsert: insert or update on (vendor_id, item_id) conflict
        const result = await pool.query(
            `INSERT INTO vendor_item_prices (vendor_id, item_id, price, updated_by, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       ON CONFLICT (vendor_id, item_id)
       DO UPDATE SET price = $3, updated_by = $4, updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
            [vendorId, item_id, price, req.user.id]
        );

        res.json({
            message: 'Price updated successfully.',
            price_record: result.rows[0]
        });
    } catch (err) {
        console.error('Set price error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

/**
 * Get all item prices for a specific vendor
 */
const getVendorPrices = async (req, res) => {
    try {
        const { vendorId } = req.params;

        const result = await pool.query(
            `SELECT vip.id, vip.item_id, i.item_name, i.description,
              vip.price, vip.updated_at, u.username AS updated_by
       FROM vendor_item_prices vip
       JOIN items i ON i.id = vip.item_id
       LEFT JOIN users u ON u.id = vip.updated_by
       WHERE vip.vendor_id = $1
       ORDER BY i.item_name ASC`,
            [vendorId]
        );

        res.json({ vendor_id: parseInt(vendorId), prices: result.rows });
    } catch (err) {
        console.error('Get vendor prices error:', err);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

module.exports = { setPrice, getVendorPrices };
