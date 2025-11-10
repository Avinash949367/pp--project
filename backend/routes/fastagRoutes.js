const express = require('express');
const passport = require('passport');
const {
  getBalance,
  recharge,
  confirmUpiPayment,
  payToll,
  getTransactionHistory,
  linkVehicle,
  deactivateFastag,
  generateFastagId,
  applyForFastag,
  verifyRazorpayPayment
} = require('../controllers/fastagController');

const router = express.Router();

// Handle OPTIONS requests for CORS preflight
router.options('*', (req, res) => res.sendStatus(200));

// TEMPORARY: Test endpoint without auth for FASTAG generation (REMOVE AFTER TESTING)
router.post('/generate-test', generateFastagId);

// Middleware to ensure user is authenticated
const requireAuth = (req, res, next) => {
  passport.authenticate('jwt', { session: false }, (err, user, info) => {
    if (err) {
      return res.status(500).json({ message: 'Internal server error' });
    }
    if (!user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    req.user = user;
    next();
  })(req, res, next);
};

// All fastag routes require authentication
router.use(requireAuth);

// Get FASTAG balance
router.get('/balance', getBalance);

// Recharge FASTAG
router.post('/recharge', recharge);

// Confirm UPI payment
router.post('/confirm-upi', confirmUpiPayment);

// Verify Razorpay payment
router.post('/verify-razorpay-payment', verifyRazorpayPayment);

// Pay toll
router.post('/pay-toll', payToll);

// Get transaction history
router.get('/transactions', getTransactionHistory);

// Link vehicle to FASTAG
router.post('/link-vehicle', linkVehicle);

// Deactivate FASTAG
router.post('/deactivate', deactivateFastag);

// Generate FASTAG ID (TEMPORARY: no auth for testing)
router.post('/generate', generateFastagId);

// Apply for new FASTAG
router.post('/apply', applyForFastag);

// Razorpay webhook (no auth required)
router.post('/razorpay-webhook', express.raw({ type: 'application/json' }), require('../controllers/fastagController').handleRazorpayWebhook);

// Stripe webhook (no auth required)
router.post('/webhook', express.raw({ type: 'application/json' }), require('../controllers/fastagController').handleStripeWebhook);

module.exports = router;
