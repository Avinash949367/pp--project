const express = require("express");
const passport = require("passport");
const { register, login, googleCallback, getUserCount, getUsersList, deleteUsersExceptAdmins, googleSignIn, verifyOtp, getProfile } = require("../controllers/authController");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const StoreAdminCredentials = require("../models/StoreAdminCredentials");

const DEFAULT_STORE_ADMIN_PASSWORD = "stationaccess";

const router = express.Router();

// Handle OPTIONS requests for CORS preflight
router.options('/login', (req, res) => res.sendStatus(200));
router.options('/signup', (req, res) => res.sendStatus(200));
router.options('/verify-otp', (req, res) => res.sendStatus(200));

router.post("/signup", register);
// Regular login route - reject admin attempts
router.post("/login", async (req, res, next) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (user && user.role === 'admin') {
      return res.status(403).json({
        message: 'Admin users must login via the admin login page'
      });
    }
    // Proceed with regular login
    login(req, res, next);
  } catch (err) {
    next(err);
  }
});
router.post("/verify-otp", verifyOtp);

// Get user profile
router.get('/profile', passport.authenticate('jwt', { session: false }), getProfile);

// Admin login route with role check and referrer validation
router.post("/admin/login", async (req, res, next) => {
  // Verify request came from admin login page
  const referrer = req.get('Referrer');
  if (!referrer || !referrer.includes('adminlogin.html')) {
    return res.status(403).json({ message: 'Admin login only allowed from admin portal' });
  }
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }
    if (user.role !== "admin") {
      return res.status(403).json({ message: "Access denied: Not an admin" });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET || "default_jwt_secret_key",
      { expiresIn: "1d" }
    );
    res.json({
      token,
      user: { name: user.name, role: user.role },
    });
  } catch (err) {
    next(err);
  }
});

// New routes for admin to get user count and user list
const ensureAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Access denied' });
  }
};

router.get('/users/count', passport.authenticate('jwt', { session: false }), ensureAdmin, getUserCount);
router.get('/users/list', passport.authenticate('jwt', { session: false }), ensureAdmin, getUsersList);
router.delete('/users/clear', passport.authenticate('jwt', { session: false }), ensureAdmin, deleteUsersExceptAdmins);



// Store admin login route - authenticate user with role 'store admin'
router.post("/storeadmin/login", async (req, res, next) => {
  const { email, password } = req.body;
  try {
    const credentials = await StoreAdminCredentials.findOne({ email });
    if (!credentials) {
      console.log('StoreAdminCredentials not found for email:', email);
      return res.status(400).json({ message: "No user found" });
    }
    console.log('Stored password hash:', credentials.password);
    console.log('Password received:', password);
    let isMatch = await bcrypt.compare(password, credentials.password);
    console.log('Password match result:', isMatch);
    if (!isMatch) {
      // Check if password matches the default password
      if (password === DEFAULT_STORE_ADMIN_PASSWORD) {
        isMatch = true;
        console.log('Login with default password successful');
      }
    }
    if (!isMatch) {
      return res.status(403).json({ message: "Access denied: Invalid credentials" });
    }

    // Get the string stationId from the Station document
    const Station = require('../models/Station');
    let stationId = null;
    const station = await Station.findById(credentials.stationId);
    if (station) {
      stationId = station.stationId; // string stationId
    }

    const token = jwt.sign(
      { id: credentials._id, email: credentials.email, role: 'store admin' },
      process.env.JWT_SECRET || "default_jwt_secret_key",
      { expiresIn: "1d" }
    );
    res.json({
      token,
      user: { email: credentials.email, role: 'store admin', stationId },
      redirectUrl: "station_admin_dashboard.html",
    });
  } catch (err) {
    next(err);
  }
});

// Google OAuth routes
router.get('/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] }));

router.get('/auth/google/callback',
  passport.authenticate('google', { failureRedirect: '/userlogin.html' }),
  googleCallback);

// New route for Flutter app Google sign-in
router.post('/auth/google-signin', googleSignIn);

router.post('/admin/users/:userId/unban', passport.authenticate('jwt', { session: false }), ensureAdmin, async (req, res) => {
  console.log('Unban request received for userId:', req.params.userId);
  try {
    const userId = req.params.userId;
    const user = await User.findById(userId);
    if (!user) {
      console.log('User not found for unban:', userId);
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    if (user.role !== 'banned') {
      console.log('User is not banned:', userId);
      return res.status(400).json({ success: false, message: 'User is not banned' });
    }
    user.role = 'user'; // or set to default role as needed
    await user.save();
    console.log('User unbanned successfully:', userId);
    res.json({ success: true, message: 'User unbanned successfully' });
  } catch (error) {
    console.error('Error unbanning user:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

module.exports = router;
