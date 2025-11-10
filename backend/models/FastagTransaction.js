const mongoose = require('mongoose');

const fastagTransactionSchema = new mongoose.Schema({
  vehicleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  vehicleNumber: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['recharge', 'toll_payment', 'refund', 'deduction'],
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  method: {
    type: String,
    enum: ['upi', 'card', 'wallet', 'auto-deduction', 'razorpay'],
    required: true
  },
  location: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['completed', 'pending', 'failed', 'success'],
    default: 'completed'
  },
  txnId: {
    type: String,
    required: true
  },
  description: {
    type: String,
    trim: true
  },
  date: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for efficient queries
fastagTransactionSchema.index({ userId: 1, createdAt: -1 });
fastagTransactionSchema.index({ vehicleNumber: 1 });

module.exports = mongoose.model('FastagTransaction', fastagTransactionSchema);
