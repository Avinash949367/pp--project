const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  phone: {
    type: String,
    trim: true
  },
  password: {
    type: String,
    required: true
  },
  vehicle: {
    type: String,
    trim: true
  },
  profileImage: {
    type: String,
    trim: true,
    default: ''  // URL or path to profile image
  },
  vehicleType: {
    type: String,
    trim: true
  },
  upiId: {
    type: String,
    trim: true
  },
  fastagId: {
    type: String,
    unique: true,
    sparse: true,
    trim: true
  },
  membershipStatus: {
    type: String,
    enum: ['Basic', 'Premium', 'Gold'],
    default: 'Basic'
  },
  walletBalance: {
    type: Number,
    default: 0
  },
  savedVehicles: [{
    type: String,
    trim: true
  }],
  preferredSpots: [{
    type: String,
    trim: true
  }],
  role: {
    type: String,
    enum: ["user", "admin", "banned"],
    default: "user"
  },
  isConfirmed: {
    type: Boolean,
    default: false,
  },
  disabledUntil: {
    type: Date,
    default: null,
  },
  confirmationToken: {
    type: String,
  },
  otpExpiry: {
    type: Date,
  },
}, {
  timestamps: true
});

// Hash password before saving - only hash if password is not already hashed
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    // For admin users with default password, don't re-hash
    if (this.password === 'store@Login.1' && this.role === 'admin') {
      return next();
    }
    
    // Check if password is already hashed (bcrypt hashes start with $2a$, $2b$, $2y$)
    if (this.password.startsWith('$2a$') || this.password.startsWith('$2b$') || this.password.startsWith('$2y$')) {
      console.log('Password appears to be already hashed, skipping re-hashing');
      return next();
    }
    
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) {
    next(err);
  }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
  console.log('Comparing passwords:');
  console.log('Stored password (hashed):', this.password);
  console.log('Candidate password:', candidatePassword);
  console.log('User role:', this.role);
  
  // For admin default password, do direct comparison
  if (this.password === 'store@Login.1' && this.role === 'admin') {
    console.log('Using direct comparison for admin default password');
    const result = candidatePassword === this.password;
    console.log('Direct comparison result:', result);
    return result;
  }
  
  console.log('Using bcrypt comparison');
  const result = await bcrypt.compare(candidatePassword, this.password);
  console.log('Bcrypt comparison result:', result);
  return result;
};

module.exports = mongoose.model("User", userSchema);
