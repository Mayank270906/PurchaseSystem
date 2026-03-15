-- Seed script: creates default admin user
-- Password: admin123 (bcrypt hash)
-- You can change the password after first login

INSERT INTO users (username, email, password_hash, role)
VALUES (
    'admin',
    'admin@purchase-registry.com',
    '$2a$10$8KzaN2J2Z9Q5Q5Q5Q5Q5QOzN6j5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5',
    'admin'
) ON CONFLICT (username) DO NOTHING;
