const express = require('express');
const router = express.Router();
const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;
const {
  getUserProfile,
  updateUserProfile,
  changeUserPassword,
  getUserDashboard,
  getUserVehicles,
  getUserPayments,
  addVehicle,
  setPrimaryVehicle,
  removeVehicle,
  addFavorite,
  removeFavorite,
  uploadProfileImage,
  getUserFastTag,
  applyForUserFastTag,
  rechargeUserFastTag,
  deactivateUserFastTag,
  getFastagTransactions,
  rechargeFastag,
  applyForFastag,
  getUserActivities,
  getUserBookings
} = require('../controllers/userProfileController');
const jwt = require('jsonwebtoken');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Middleware to protect routes with JWT authentication
const ensureAuthenticated = (req, res, next) => {
  // For JWT token authentication
  const token = req.header('Authorization')?.replace('Bearer ', '');
  console.log('ensureAuthenticated middleware: token:', token);
  if (!token) {
    console.log('ensureAuthenticated middleware: No token found');
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default_jwt_secret_key');
    console.log('ensureAuthenticated middleware: decoded token:', decoded);
    req.user = decoded;
    next();
  } catch (error) {
    console.log('ensureAuthenticated middleware: token verification error:', error.message);
    res.status(401).json({ message: 'Token is not valid' });
  }
};

// Cloudinary storage setup for profile image upload
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'park-pro/profile-images',
    allowed_formats: ['jpg', 'jpeg', 'png', 'gif'],
    transformation: [{ width: 300, height: 300, crop: 'fill' }],
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: function (req, file, cb) {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

// User profile routes
router.get('/profile', ensureAuthenticated, getUserProfile);
router.put('/profile', ensureAuthenticated, updateUserProfile);
router.post('/profile/change-password', ensureAuthenticated, changeUserPassword);
router.get('/dashboard', ensureAuthenticated, getUserDashboard);

// Vehicle routes
router.get('/vehicles', ensureAuthenticated, getUserVehicles);
router.post('/vehicles', ensureAuthenticated, addVehicle);
router.patch('/vehicles/:id/primary', ensureAuthenticated, setPrimaryVehicle);
router.delete('/vehicles/:id', ensureAuthenticated, removeVehicle);

// Payment routes
router.get('/payments', ensureAuthenticated, getUserPayments);

// Favorite routes
router.post('/favorites', ensureAuthenticated, addFavorite);
router.delete('/favorites/:id', ensureAuthenticated, removeFavorite);

// Profile image upload route
router.post('/profile/upload-image', ensureAuthenticated, upload.single('profileImage'), uploadProfileImage);

// FastTag routes
router.get('/fasttag', ensureAuthenticated, getUserFastTag);
router.post('/fasttag/apply', ensureAuthenticated, applyForUserFastTag);
router.post('/fasttag/recharge', ensureAuthenticated, rechargeUserFastTag);
router.post('/fasttag/deactivate', ensureAuthenticated, deactivateUserFastTag);
router.get('/vehicles/:vehicleId/fastag/transactions', ensureAuthenticated, getFastagTransactions);
router.post('/vehicles/:vehicleId/fastag/recharge', ensureAuthenticated, rechargeFastag);
router.post('/vehicles/:vehicleId/fastag/apply', ensureAuthenticated, applyForFastag);

// Activity and booking routes
router.get('/activities', ensureAuthenticated, getUserActivities);
router.get('/bookings', ensureAuthenticated, getUserBookings);

module.exports = router;
