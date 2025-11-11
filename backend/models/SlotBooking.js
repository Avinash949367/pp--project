const mongoose = require('mongoose');

const slotBookingSchema = new mongoose.Schema({
  slotId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Slot',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  vehicleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: true
  },
  stationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Station',
    required: true
  },
  bookingStartTime: {
    type: Date,
    required: true
  },
  bookingEndTime: {
    type: Date,
    required: true
  },
  amountPaid: {
    type: Number,
    required: true
  },
  paymentMethod: {
    type: String,
    enum: ['upi', 'coupon', 'razorpay'],
    required: true
  },
  paymentStatus: {
    type: String,
    enum: ['success', 'failed', 'pending'],
    default: 'pending'
  },
  status: {
    type: String,
    enum: ['reserved', 'active', 'confirmed', 'cancelled', 'expired'],
    default: 'reserved'
  },
  reservationExpiresAt: {
    type: Date,
    required: false,
    default: null
  },
  cancelReason: {
    type: String,
    enum: ['user_cancelled', 'timeout', 'system_error', null],
    default: null
  },
  razorpayOrderId: {
    type: String,
    required: false,
    default: null
  },
  razorpayPaymentId: {
    type: String,
    required: false,
    default: null
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('SlotBooking', slotBookingSchema);
