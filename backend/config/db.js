/**
 * PostgreSQL Connection Pool
 * 
 * Supports two modes:
 * - DATABASE_URL env var (used by Render, Railway, etc.)
 * - Individual DB_HOST/DB_PORT/etc. vars (local dev)
 */

const { Pool } = require('pg');

const poolConfig = process.env.DATABASE_URL
  ? {
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  }
  : {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASS || 'postgres',
    database: process.env.DB_NAME || 'purchase_registry',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  };

const pool = new Pool(poolConfig);

// Log successful connection on first query
pool.on('connect', () => {
  console.log('📦 Connected to PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected PostgreSQL error:', err);
  process.exit(-1);
});

module.exports = pool;
