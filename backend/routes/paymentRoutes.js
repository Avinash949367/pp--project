const express = require('express');
const router = express.Router();
const passport = require('passport');
const paymentController = require('../controllers/paymentController');

// Payment routes for station admin
router.get('/station/today', passport.authenticate('jwt', { session: false }), paymentController.getTodayEarnings);
router.get('/station/daily', passport.authenticate('jwt', { session: false }), paymentController.getDailyEarnings);
router.get('/station/monthly', passport.authenticate('jwt', { session: false }), paymentController.getMonthlyEarnings);
router.get('/station/breakdown', passport.authenticate('jwt', { session: false }), paymentController.getPaymentBreakdown);

module.exports = router;
