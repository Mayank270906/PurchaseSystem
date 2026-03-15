/**
 * Purchase Registry Backend - Server Entry Point
 * 
 * Express application with:
 * - CORS enabled for mobile app
 * - JSON body parsing
 * - Route modules for each domain
 * - Global error handler
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();

// ─── Middleware ───────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── Health Check ────────────────────────────────────────
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Routes ──────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/items', require('./routes/items'));
app.use('/api/vendors', require('./routes/vendors'));
app.use('/api/purchases', require('./routes/purchases'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/dashboard', require('./routes/dashboard'));

// ─── 404 Handler ─────────────────────────────────────────
app.use((req, res) => {
    res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Global Error Handler ────────────────────────────────
app.use((err, req, res, next) => {
    console.error('❌ Unhandled Error:', err.stack);
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// ─── Start Server ────────────────────────────────────────
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`🚀 Purchase Registry API running on port ${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
