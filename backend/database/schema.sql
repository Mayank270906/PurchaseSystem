-- Purchase Registry System - Database Schema
-- PostgreSQL 12+

-- Role enum for user types
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'user');

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Items table
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vendors table
CREATE TABLE vendors (
    id SERIAL PRIMARY KEY,
    vendor_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vendor-specific item prices (prices vary by vendor)
CREATE TABLE vendor_item_prices (
    id SERIAL PRIMARY KEY,
    vendor_id INTEGER NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    price DECIMAL(12, 2) NOT NULL CHECK (price >= 0),
    updated_by INTEGER NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (vendor_id, item_id)
);

-- Purchases recorded by users (no price stored here)
CREATE TABLE purchases (
    id SERIAL PRIMARY KEY,
    vendor_id INTEGER NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    quantity DECIMAL(12, 3) NOT NULL CHECK (quantity > 0),
    datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    recorded_by INTEGER NOT NULL REFERENCES users(id)
);

-- Payments recorded by managers
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    vendor_id INTEGER NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    purpose VARCHAR(255),
    payment_method VARCHAR(50),
    datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    recorded_by INTEGER NOT NULL REFERENCES users(id),
    notes TEXT
);

-- Indexes for performance
CREATE INDEX idx_vendor_item_prices_vendor ON vendor_item_prices(vendor_id);
CREATE INDEX idx_vendor_item_prices_item ON vendor_item_prices(item_id);
CREATE INDEX idx_purchases_vendor ON purchases(vendor_id);
CREATE INDEX idx_purchases_item ON purchases(item_id);
CREATE INDEX idx_purchases_datetime ON purchases(datetime);
CREATE INDEX idx_purchases_recorded_by ON purchases(recorded_by);
CREATE INDEX idx_payments_vendor ON payments(vendor_id);
CREATE INDEX idx_payments_datetime ON payments(datetime);
CREATE INDEX idx_payments_recorded_by ON payments(recorded_by);
