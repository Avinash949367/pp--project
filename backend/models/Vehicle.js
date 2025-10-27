const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['car', 'bike', 'ev', 'lcv', 'bus', '3axle', '4axle', 'heavy'],
    required: true
  },
  number: {
    type: String,
    unique: true,
    required: true,
    trim: true
  },
  isPrimary: {
    type: Boolean,
    default: false
  },
  fastTag: {
    tagId: {
      type: String,
      unique: true,
      sparse: true
    },
    balance: {
      type: Number,
      default: 0
    },
    status: {
      type: String,
      enum: ['active', 'disabled'],
      default: 'active'
    }
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Vehicle', vehicleSchema);
