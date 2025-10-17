const express = require('express');
const router = express.Router();
const {
  getAllUsers,
  getUserById,
  getUserByEmail,
  updateUser,
  deleteUser,
  banUser,
  disableUser
} = require('../controllers/userController');
const jwt = require('jsonwebtoken');

// Middleware to protect routes with JWT authentication
const ensureAuthenticated = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default_jwt_secret_key');
    req.user = decoded;

    // Check if user is banned
    if (decoded.role === 'banned') {
      return res.status(403).json({ message: 'Account is banned. Access denied.' });
    }

    // Check if user is temporarily disabled
    if (decoded.disabledUntil && new Date(decoded.disabledUntil) > new Date()) {
      return res.status(403).json({
        message: 'Account is temporarily disabled. Please try again later.',
        disabledUntil: decoded.disabledUntil
      });
    }

    next();
  } catch (error) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

// Middleware to check if user is admin
const ensureAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin role required.' });
  }
  next();
};

// Admin user management routes
router.get('/admin/users', ensureAuthenticated, ensureAdmin, getAllUsers);
router.get('/admin/users/:id', ensureAuthenticated, ensureAdmin, getUserById);
router.put('/admin/users/:id', ensureAuthenticated, ensureAdmin, updateUser);
router.delete('/admin/users/:id', ensureAuthenticated, ensureAdmin, deleteUser);
router.post('/admin/users/:id/ban', ensureAuthenticated, ensureAdmin, banUser);
router.post('/admin/users/:id/disable', ensureAuthenticated, ensureAdmin, disableUser);

// General users route (admin only)
router.get('/users', ensureAuthenticated, ensureAdmin, getAllUsers);

// Get user by email (for Flutter app)
router.get('/users/email/:email', getUserByEmail);

module.exports = router;
