/**
 * JWT Authentication Middleware
 * 
 * Verifies the JWT token from the Authorization header.
 * Attaches decoded user info (id, username, role) to req.user.
 * Returns 401 if token is missing or invalid.
 */

const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
    try {
        // Extract token from 'Bearer <token>' format
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Access denied. No token provided.' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Attach user info to request object
        req.user = {
            id: decoded.id,
            username: decoded.username,
            role: decoded.role
        };

        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token.' });
    }
};

module.exports = auth;
