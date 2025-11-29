const express = require('express');
const router = express.Router();
const passport = require('passport');
const slotController = require('../controllers/slotController');

// Get all slots
router.get('/', slotController.getAllSlots);

// Get slot by slotId
router.get('/slot/:slotId', slotController.getSlotById);

// Get all slots for a station
router.get('/station/:stationId', slotController.getSlotsByStation);

// Create a new slot
router.post('/', slotController.createSlot);

// Update a slot
router.put('/:id', slotController.updateSlot);

// Delete a slot
router.delete('/:id', slotController.deleteSlot);

// Get bookings for a slot
router.get('/:id/bookings', slotController.getSlotBookings);

// Create a new booking for a slot
router.post('/:id/bookings', passport.authenticate('jwt', { session: false }), slotController.createBooking);

// Delete image from Cloudinary
router.delete('/delete-image', slotController.deleteImage);

// Get slot availability for a date
router.get('/:id/availability', slotController.getSlotAvailability);

// Get station availability for a date
router.get('/stations/:id/availability', slotController.getStationAvailability);

// Reserve a booking
router.post('/bookings/reserve', passport.authenticate('jwt', { session: false }), slotController.reserveBooking);

// Verify payment
router.post('/payments/verify', slotController.verifyPayment);

// Verify Razorpay payment
router.post('/payments/razorpay/verify', passport.authenticate('jwt', { session: false }), slotController.verifyRazorpayPayment);

// Test route
router.get('/test', (req, res) => res.send('slot routes working'));

// Get dashboard stats for station admin
router.get('/dashboard-stats/:stationId', slotController.getDashboardStats);

// Get recent bookings for station admin
router.get('/recent-bookings/:stationId', slotController.getRecentBookings);

// Get slot bookings by user ID
router.get('/slotbookings/:userId', slotController.getSlotBookingsByUserId);

// Cancel a booking
router.put('/bookings/:bookingId/cancel', passport.authenticate('jwt', { session: false }), slotController.cancelBooking);

// Get earnings data for station admin
router.get('/earnings/:stationId', slotController.getEarningsData);

// Get recent transactions for station admin
router.get('/transactions/:stationId', slotController.getRecentTransactions);

// Get booking data for station admin table
router.get('/bookings-data/:stationId', slotController.getBookingsData);

module.exports = router;
