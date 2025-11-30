const express = require('express');
const router = express.Router();
const passport = require('passport');
const bookingController = require('../controllers/bookingController');

// Booking routes for station admin
router.get('/station/current', passport.authenticate('jwt', { session: false }), bookingController.getCurrentBookings);
router.get('/station/all', passport.authenticate('jwt', { session: false }), bookingController.getAllBookings);

module.exports = router;
