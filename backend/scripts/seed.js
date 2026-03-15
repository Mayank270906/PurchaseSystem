/**
 * Seed Script
 * 
 * Creates the default admin user with a properly hashed password.
 * Run: npm run seed
 * 
 * Default credentials:
 *   Username: admin
 *   Password: admin123
 */

require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const fs = require('fs');
const path = require('path');

async function seed() {
    try {
        console.log('🌱 Starting database seed...\n');

        // Step 1: Run schema.sql to create tables
        const schemaPath = path.join(__dirname, '..', 'database', 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf-8');

        console.log('📋 Creating database tables...');
        await pool.query(schema);
        console.log('✅ Tables created successfully.\n');

        // Step 2: Create default admin user
        console.log('👤 Creating default admin user...');
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash('admin123', salt);

        await pool.query(
            `INSERT INTO users (username, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (username) DO NOTHING`,
            ['admin', 'admin@purchase-registry.com', passwordHash, 'admin']
        );
        console.log('✅ Admin user created (username: admin, password: admin123)\n');

        console.log('🎉 Database seeded successfully!');
        console.log('   You can now start the server with: npm run dev');

        process.exit(0);
    } catch (err) {
        console.error('❌ Seed error:', err.message);
        process.exit(1);
    }
}

seed();
