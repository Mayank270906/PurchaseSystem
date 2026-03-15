// fix_admin.js
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function run() {
    try {
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash('admin123', salt);

        // Create or update admin user
        await pool.query(`
      INSERT INTO users (username, email, password_hash, role)
      VALUES ('admin', 'admin@purchase-registry.com', $1, 'admin')
      ON CONFLICT (username) DO UPDATE 
      SET password_hash = $1, role = 'admin'
    `, [hash]);

        console.log('✅ Admin user password successfully set to: admin123');
        process.exit(0);
    } catch (e) {
        console.error('Error:', e.message);
        process.exit(1);
    }
}

run();
