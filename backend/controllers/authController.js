const User = require("../models/User");
const UserRole = require("../models/UserRole");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");

// Setup nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER, // your email address to send from
    pass: process.env.EMAIL_PASS, // your email password or app password
  },
});

// Helper function to generate OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6 digit OTP
}

// Helper function to validate password complexity
function validatePassword(password) {
  const errors = [];

  // Check for at least one uppercase letter
  if (!/[A-Z]/.test(password)) {
    errors.push("uppercase letter");
  }

  // Check for at least one lowercase letter
  if (!/[a-z]/.test(password)) {
    errors.push("lowercase letter");
  }

  // Check for at least one number
  if (!/[0-9]/.test(password)) {
    errors.push("number");
  }

  // Check for at least one special character
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push("special character");
  }

  return errors;
}

// Signup Controller with OTP email
exports.register = async (req, res) => {
  const { name, email, role, password } = req.body;

  // Email validation for @gmail.com
  if (!email.endsWith('@gmail.com')) {
    console.log('Invalid email domain for signup:', email);
    return res.status(400).json({ message: "Only Gmail addresses are allowed for registration" });
  }

  // Name length validation
  if (name.length > 10) {
    console.log('Name too long:', name);
    return res.status(400).json({ message: "Name must not exceed 10 characters" });
  }

  // Password validation
  const passwordErrors = validatePassword(password);
  if (passwordErrors.length > 0) {
    const errorMessage = `Password must contain at least one ${passwordErrors.join(', ')}`;
    console.log('Password validation failed:', errorMessage);
    return res.status(400).json({ message: errorMessage });
  }

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: "User already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // OTP valid for 10 minutes

    const user = await User.create({
      name,
      email,
      role,
      password: hashedPassword,
      isConfirmed: true, // Temporarily set to true for testing without OTP
      confirmationToken: null,
      otpExpiry: null,
    });

    // OTP email sending commented out for testing
    /*
    // Send OTP email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: "Your OTP for Park Pro Signup",
      text: `Your OTP for account verification is: ${otp}. It is valid for 10 minutes.`,
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error("Error sending OTP email:", error);
      } else {
        console.log("OTP email sent:", info.response);
      }
    });
    */

    res.status(201).json({ message: "Registered successfully." });
  } catch (err) {
    res.status(500).json({ message: "Error registering", error: err.message });
  }
};

// OTP Verification Controller
exports.verifyOtp = async (req, res) => {
  const { email, otp } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "User not found" });

    if (user.isConfirmed) return res.status(400).json({ message: "User already verified" });

    if (user.confirmationToken !== otp) return res.status(400).json({ message: "Invalid OTP" });

    if (user.otpExpiry < new Date()) return res.status(400).json({ message: "OTP expired" });

    user.isConfirmed = true;
    user.confirmationToken = null;
    user.otpExpiry = null;
    await user.save();

    res.json({ message: "Account verified successfully" });
  } catch (err) {
    res.status(500).json({ message: "Error verifying OTP", error: err.message });
  }
};

// Login Controller with verification check
exports.login = async (req, res) => {
  const { email, password } = req.body;

  console.log('Login attempt for email:', email);
  console.log('Password received:', password);

  // Email validation for @gmail.com
  if (!email.endsWith('@gmail.com')) {
    console.log('Invalid email domain:', email);
    return res.status(400).json({ message: "Only Gmail addresses are allowed for login" });
  }

  try {
    const user = await User.findOne({ email });
    if (!user) {
      console.log('User not found for email:', email);
      return res.status(400).json({ message: "User not found" });
    }

    console.log('User found:', user.email, 'Role:', user.role, 'Confirmed:', user.isConfirmed);

    // Temporarily comment out confirmation check for testing
    /*
    if (!user.isConfirmed && user.role !== 'admin') {
      console.log('Account not confirmed for user:', user.email);
      return res.status(400).json({ message: "Account not confirmed. Please verify your email." });
    }
    */

    console.log('About to compare passwords...');
    let isMatch = await bcrypt.compare(password, user.password);
    // For store admin, also allow default password "stationaccess"
    if (user.role === 'store admin' && password === 'stationaccess') {
      isMatch = true;
    }
    console.log('Password comparison result:', isMatch);

    if (!isMatch) {
      console.log('Password mismatch for user:', user.email);
      return res.status(400).json({ message: "Invalid credentials" });
    }

    console.log('Login successful for user:', user.email);

    // Create or update UserRole
    let userRole = await UserRole.findOne({ userId: user._id });
    if (!userRole) {
      userRole = new UserRole({ userId: user._id });
    }
    userRole.lastLogin = new Date();
    await userRole.save();

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET || 'default_jwt_secret_key',
      { expiresIn: "7d" }
    );

    const StoreAdminCredentials = require('../models/StoreAdminCredentials');
    const Station = require('../models/Station');
    let stationId = null;
    if (user.role === 'store admin') {
      // Find the stationId for this store admin user
      const credentials = await StoreAdminCredentials.findOne({ email: user.email });
      if (credentials) {
        // credentials.stationId is the Station._id (ObjectId), find the Station to get the string stationId
        const station = await Station.findById(credentials.stationId);
        if (station) {
          stationId = station.stationId; // This is the string stationId field
        }
      }
    }

    res.json({
      token,
      user: { _id: user._id, name: user.name, email: user.email, role: user.role, stationId },
    });
  } catch (err) {
    console.error('Error during login:', err.message);
    res.status(500).json({ message: "Error logging in", error: err.message });
  }
};

// New controller to get total user count (admin only)
exports.getUserCount = async (req, res) => {
  try {
    // Check if user is admin
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }
    const count = await User.countDocuments();
    res.json({ totalUsers: count });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching user count', error: err.message });
  }
};

// OAuth callback handlers
exports.googleCallback = (req, res) => {
  // Successful authentication, issue JWT and redirect or respond
  const user = req.user;
  const token = jwt.sign(
    { id: user._id, role: user.role },
    'default_jwt_secret_key',
    { expiresIn: "1d" }
  );
  // Redirect to frontend with token and user data
  res.redirect(`/index.html?token=${token}&user=${encodeURIComponent(JSON.stringify(user))}&email=${encodeURIComponent(user.email)}`);
};

exports.getUsersList = async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }
    const users = await User.find({}, 'name email role password');
    res.json({ users });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching users list', error: err.message });
  }
};

// Controller to delete all users except admins
exports.deleteUsersExceptAdmins = async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }
    const result = await User.deleteMany({ role: { $ne: 'admin' } });
    res.json({ message: `Deleted ${result.deletedCount} users except admins` });
  } catch (err) {
    res.status(500).json({ message: 'Error deleting users', error: err.message });
  }
};

// Add this function to your existing authController.js file manually:
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Get user profile
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      vehicle: user.vehicle,
      vehicleType: user.vehicleType,
      fastagId: user.fastagId,
      walletBalance: user.walletBalance || 0
    });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
};

exports.googleSignIn = async (req, res) => {
  const { idToken } = req.body;

  try {
    // Verify the idToken with Google
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const { email, name } = payload;

    // Check if user exists
    let user = await User.findOne({ email });

    if (!user) {
      // Create new user
      user = await User.create({
        name,
        email,
        role: 'user', // default role
        password: '', // no password for OAuth users
      });
    }

    // Create or update UserRole
    let userRole = await UserRole.findOne({ userId: user._id });
    if (!userRole) {
      userRole = new UserRole({ userId: user._id });
    }
    userRole.lastLogin = new Date();
    await userRole.save();

    // Issue JWT token
    const token = jwt.sign(
      { id: user._id, role: user.role },
      'default_jwt_secret_key',
      { expiresIn: "1d" }
    );

    res.json({ token, user: { name: user.name, role: user.role } });
  } catch (err) {
    res.status(401).json({ message: "Invalid Google token", error: err.message });
  }
};
