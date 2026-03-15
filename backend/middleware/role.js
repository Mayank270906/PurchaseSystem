/**
 * Role-Based Access Control Middleware
 * 
 * Factory function that returns middleware checking if the
 * authenticated user's role is in the allowed roles list.
 * Must be used AFTER the auth middleware.
 * 
 * Usage: requireRole('admin', 'manager')
 */

const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required.' });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                error: 'Access denied. Insufficient permissions.',
                required: allowedRoles,
                current: req.user.role
            });
        }

        next();
    };
};

module.exports = requireRole;
