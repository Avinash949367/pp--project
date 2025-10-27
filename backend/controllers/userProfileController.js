const User = require('../models/User');
const UserRole = require('../models/UserRole');
const Vehicle = require('../models/Vehicle');
const FastagTransaction = require('../models/FastagTransaction');
const SlotBooking = require('../models/SlotBooking');
const ParkingHistory = require('../models/ParkingHistory');
const Station = require('../models/Station');
const Payment = require('../models/Payment');
const bcrypt = require('bcryptjs');

// Get user vehicles
const getUserVehicles = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const vehicles = await Vehicle.find({ userId }).populate('fastTag');

    res.json({
      success: true,
      vehicles
    });
  } catch (error) {
    console.error('Error fetching user vehicles:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user payments
const getUserPayments = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Get payments by joining with SlotBooking where userId matches
    const payments = await Payment.find()
      .populate({
        path: 'bookingId',
        match: { userId: userId },
        populate: [
          { path: 'stationId', select: 'name' },
          { path: 'vehicleId', select: 'number type' }
        ]
      })
      .sort({ timestamp: -1 });

    // Filter out payments where bookingId is null (booking not found or not belonging to user)
    const userPayments = payments.filter(payment => payment.bookingId !== null);

    res.json({
      success: true,
      payments: userPayments
    });
  } catch (error) {
    console.error('Error fetching user payments:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user profile
const getUserProfile = async (req, res) => {
  try {
    console.log('getUserProfile: Starting profile fetch...');
    console.log('getUserProfile: req.user:', req.user);
    const userId = req.user.id; // Assuming user ID is available from auth middleware
    console.log('getUserProfile: userId:', userId);

    const user = await User.findById(userId).select('-password');
    console.log('getUserProfile: user found:', user ? 'yes' : 'no');
    if (!user) {
      console.log('getUserProfile: User not found for id:', userId);
      return res.status(404).json({ message: 'User not found' });
    }

    let userRoleData = null;
    let vehicles = [];

    // If user has role 'user', fetch additional data from UserRole and Vehicle collections
    if (user.role === 'user') {
      console.log('getUserProfile: Fetching UserRole data for userId:', userId);
      try {
        userRoleData = await UserRole.findOne({ userId }).populate('settings.preferredVehicle');
        console.log('getUserProfile: UserRole data found:', userRoleData ? 'yes' : 'no');
      } catch (error) {
        console.log('getUserProfile: Error fetching UserRole data:', error.message);
      }

      console.log('getUserProfile: Fetching vehicles for userId:', userId);
      try {
        vehicles = await Vehicle.find({ userId }).populate('fastTag');
        console.log('getUserProfile: Vehicles found:', vehicles.length);
      } catch (error) {
        console.log('getUserProfile: Error fetching vehicles:', error.message);
      }
    }

    const profileData = {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      vehicle: user.vehicle || '',
      profileImage: user.profileImage || '',
      membershipStatus: user.membershipStatus || 'Basic',
      walletBalance: user.walletBalance || 0,
      savedVehicles: user.savedVehicles || [],
      preferredSpots: user.preferredSpots || [],
      role: user.role,
      createdAt: user.createdAt
    };

    // Add UserRole data if available
    if (userRoleData) {
      profileData.settings = userRoleData.settings;
      profileData.kycStatus = userRoleData.kycStatus;
      profileData.favorites = userRoleData.favorites;
      profileData.refreshTokens = userRoleData.refreshTokens;
      profileData.lastLogin = userRoleData.lastLogin;
      profileData.walletBalance = userRoleData.walletBalance; // Override with UserRole walletBalance
      profileData.dateOfBirth = userRoleData.dateOfBirth;
      profileData.gender = userRoleData.gender;
    }

    // Add vehicles data
    profileData.vehicles = vehicles;

    console.log('getUserProfile: Sending response with profile data');
    res.json({
      success: true,
      user: profileData
    });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update user profile
const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email, phone, vehicle, settings, kycStatus, favorites, dateOfBirth, gender } = req.body;

    // Check if email is already taken by another user
    if (email) {
      const existingUser = await User.findOne({ email, _id: { $ne: userId } });
      if (existingUser) {
        return res.status(400).json({ message: 'Email already in use' });
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { name, email, phone, vehicle },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    // If user has role 'user', update UserRole data
    if (updatedUser.role === 'user') {
      let userRole = await UserRole.findOne({ userId });

      if (!userRole) {
        // Create new UserRole document if it doesn't exist
        userRole = new UserRole({ userId });
      }

      // Update UserRole fields if provided
      if (settings !== undefined) {
        userRole.settings = { ...userRole.settings, ...settings };
      }
      if (kycStatus !== undefined) {
        userRole.kycStatus = kycStatus;
      }
      if (favorites !== undefined) {
        userRole.favorites = favorites;
      }
      if (dateOfBirth !== undefined) {
        userRole.dateOfBirth = dateOfBirth;
      }
      if (gender !== undefined) {
        userRole.gender = gender;
      }

      await userRole.save();
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        phone: updatedUser.phone,
        vehicle: updatedUser.vehicle
      }
    });
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Change user password
const changeUserPassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    user.password = hashedPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user dashboard data
const getUserDashboard = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Here you can add additional data like:
    // - Recent bookings count
    // - Upcoming reservations count
    // - Wallet balance
    // - Membership status
    // - Saved vehicles count
    // - Preferred parking spots count

    res.json({
      success: true,
      dashboard: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          vehicle: user.vehicle,
          membershipStatus: user.membershipStatus || 'Basic',
          walletBalance: user.walletBalance || 0
        },
        stats: {
          savedVehicles: user.savedVehicles ? user.savedVehicles.length : 0,
          preferredSpots: user.preferredSpots ? user.preferredSpots.length : 0,
          recentBookings: 0, // This would come from bookings collection
          upcomingReservations: 0, // This would come from reservations collection
          totalTransactions: 0 // This would come from transactions collection
        }
      }
    });
  } catch (error) {
    console.error('Error fetching user dashboard:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Add vehicle
const addVehicle = async (req, res) => {
  try {
    const userId = req.user.id;
    const { number, type, isPrimary = false } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Check if vehicle number already exists for this user
    const existingVehicle = await Vehicle.findOne({ userId, number });
    if (existingVehicle) {
      return res.status(400).json({ message: 'Vehicle already exists' });
    }

    // If this is primary, unset other primary vehicles
    if (isPrimary) {
      await Vehicle.updateMany({ userId }, { isPrimary: false });
    }

    const vehicle = new Vehicle({
      userId,
      number,
      type,
      isPrimary
    });

    await vehicle.save();

    res.json({
      success: true,
      message: 'Vehicle added successfully',
      vehicle
    });
  } catch (error) {
    console.error('Error adding vehicle:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Set primary vehicle
const setPrimaryVehicle = async (req, res) => {
  try {
    const userId = req.user.id;
    const vehicleId = req.params.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // First, unset all vehicles as primary for this user
    await Vehicle.updateMany({ userId }, { isPrimary: false });

    // Then set the specified vehicle as primary
    const vehicle = await Vehicle.findOneAndUpdate(
      { _id: vehicleId, userId },
      { isPrimary: true },
      { new: true }
    );

    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    res.json({
      success: true,
      message: 'Primary vehicle updated successfully',
      vehicle
    });
  } catch (error) {
    console.error('Error setting primary vehicle:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Remove vehicle
const removeVehicle = async (req, res) => {
  try {
    const userId = req.user.id;
    const vehicleId = req.params.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const vehicle = await Vehicle.findOneAndDelete({ _id: vehicleId, userId });
    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    res.json({
      success: true,
      message: 'Vehicle removed successfully'
    });
  } catch (error) {
    console.error('Error removing vehicle:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Add favorite station
const addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { stationId } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    let userRole = await UserRole.findOne({ userId });
    if (!userRole) {
      userRole = new UserRole({ userId });
    }

    // Check if favorite already exists
    const existingFavorite = userRole.favorites.find(fav => fav.stationId === stationId);
    if (existingFavorite) {
      return res.status(400).json({ message: 'Station already in favorites' });
    }

    userRole.favorites.push({
      stationId,
      addedAt: new Date()
    });

    await userRole.save();

    res.json({
      success: true,
      message: 'Favorite added successfully'
    });
  } catch (error) {
    console.error('Error adding favorite:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Remove favorite station
const removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const favoriteId = req.params.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const userRole = await UserRole.findOne({ userId });
    if (!userRole) {
      return res.status(404).json({ message: 'User role data not found' });
    }

    const favoriteIndex = userRole.favorites.findIndex(fav => fav._id.toString() === favoriteId);
    if (favoriteIndex === -1) {
      return res.status(404).json({ message: 'Favorite not found' });
    }

    userRole.favorites.splice(favoriteIndex, 1);
    await userRole.save();

    res.json({
      success: true,
      message: 'Favorite removed successfully'
    });
  } catch (error) {
    console.error('Error removing favorite:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Upload profile image
const uploadProfileImage = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if file was uploaded
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    // Get the Cloudinary URL
    const imageUrl = req.file.path;

    // Update user's profile image in database
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage: imageUrl },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      user: {
        id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        profileImage: updatedUser.profileImage
      }
    });
  } catch (error) {
    console.error('Error uploading profile image:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get FastTag transactions for a vehicle
const getFastagTransactions = async (req, res) => {
  try {
    const userId = req.user.id;
    const vehicleId = req.params.vehicleId;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Check if vehicle belongs to user
    const vehicle = await Vehicle.findOne({ _id: vehicleId, userId });
    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    const transactions = await FastagTransaction.find({ vehicleId })
      .sort({ date: -1 })
      .limit(20); // Get last 20 transactions

    res.json({
      success: true,
      transactions
    });
  } catch (error) {
    console.error('Error fetching FastTag transactions:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Recharge FastTag
const rechargeFastag = async (req, res) => {
  try {
    const userId = req.user.id;
    const { vehicleId, amount } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Check if vehicle belongs to user
    const vehicle = await Vehicle.findOne({ _id: vehicleId, userId });
    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    // Check if user has sufficient wallet balance
    if (user.walletBalance < amount) {
      return res.status(400).json({ message: 'Insufficient wallet balance' });
    }

    // Update vehicle FastTag balance
    vehicle.fastTag.balance += amount;
    await vehicle.save();

    // Deduct from user wallet
    user.walletBalance -= amount;
    await user.save();

    // Create transaction record
    const transaction = new FastagTransaction({
      vehicleId,
      txnId: `FT${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`,
      type: 'recharge',
      amount,
      method: 'wallet'
    });
    await transaction.save();

    res.json({
      success: true,
      message: 'FastTag recharged successfully',
      newBalance: vehicle.fastTag.balance,
      walletBalance: user.walletBalance,
      transaction
    });
  } catch (error) {
    console.error('Error recharging FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Apply for FastTag
const applyForFastag = async (req, res) => {
  try {
    const userId = req.user.id;
    const { vehicleId } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Check if vehicle belongs to user
    const vehicle = await Vehicle.findOne({ _id: vehicleId, userId });
    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    // Check if vehicle already has FastTag
    if (vehicle.fastTag && vehicle.fastTag.tagId) {
      return res.status(400).json({ message: 'Vehicle already has FastTag' });
    }

    // Generate FastTag ID
    const tagId = `FT${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

    // Update vehicle with FastTag details
    vehicle.fastTag = {
      tagId,
      balance: 0,
      status: 'active'
    };
    await vehicle.save();

    res.json({
      success: true,
      message: 'FastTag applied successfully',
      fastTag: vehicle.fastTag
    });
  } catch (error) {
    console.error('Error applying for FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user's FastTag data
const getUserFastTag = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Get user's vehicles with FastTag data
    const vehicles = await Vehicle.find({ userId }).populate('fastTag');

    // Find the primary vehicle or first vehicle with FastTag
    let fastTagData = null;
    let linkedVehicle = null;

    const primaryVehicle = vehicles.find(v => v.isPrimary);
    const vehicleWithFastTag = vehicles.find(v => v.fastTag && v.fastTag.tagId);

    const activeVehicle = primaryVehicle || vehicleWithFastTag || vehicles[0];

    if (activeVehicle && activeVehicle.fastTag && activeVehicle.fastTag.tagId) {
      fastTagData = {
        tagId: activeVehicle.fastTag.tagId,
        balance: activeVehicle.fastTag.balance || 0,
        status: activeVehicle.fastTag.status || 'inactive',
        isActive: activeVehicle.fastTag.status === 'active'
      };
      linkedVehicle = {
        _id: activeVehicle._id,
        number: activeVehicle.number,
        type: activeVehicle.type
      };
    }

    // Get last transaction
    let lastTransaction = null;
    if (activeVehicle) {
      const transaction = await FastagTransaction.findOne({ vehicleId: activeVehicle._id })
        .sort({ date: -1 });
      if (transaction) {
        lastTransaction = {
          amount: transaction.amount,
          location: 'Parking Station', // This could be enhanced with actual location data
          date: transaction.date
        };
      }
    }

    res.json({
      success: true,
      fastTag: fastTagData ? {
        ...fastTagData,
        linkedVehicle,
        lastTransaction
      } : null
    });
  } catch (error) {
    console.error('Error fetching user FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Apply for FastTag for user
const applyForUserFastTag = async (req, res) => {
  try {
    const userId = req.user.id;
    const { vehicleId } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Check if vehicle belongs to user
    const vehicle = await Vehicle.findOne({ _id: vehicleId, userId });
    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    // Check if vehicle already has FastTag
    if (vehicle.fastTag && vehicle.fastTag.tagId) {
      return res.status(400).json({ message: 'Vehicle already has FastTag' });
    }

    // Generate FastTag ID
    const tagId = `FT${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

    // Update vehicle with FastTag details
    vehicle.fastTag = {
      tagId,
      balance: 0,
      status: 'active'
    };
    await vehicle.save();

    res.json({
      success: true,
      message: 'FastTag applied successfully',
      fastTag: vehicle.fastTag
    });
  } catch (error) {
    console.error('Error applying for user FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Recharge user's FastTag
const rechargeUserFastTag = async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Get user's vehicles with FastTag
    const vehicles = await Vehicle.find({ userId, 'fastTag.tagId': { $exists: true } });

    if (vehicles.length === 0) {
      return res.status(400).json({ message: 'No FastTag found for user' });
    }

    // Use primary vehicle or first vehicle with FastTag
    const primaryVehicle = vehicles.find(v => v.isPrimary);
    const vehicle = primaryVehicle || vehicles[0];

    // Check if user has sufficient wallet balance
    if (user.walletBalance < amount) {
      return res.status(400).json({ message: 'Insufficient wallet balance' });
    }

    // Update vehicle FastTag balance
    vehicle.fastTag.balance += amount;
    await vehicle.save();

    // Deduct from user wallet
    user.walletBalance -= amount;
    await user.save();

    // Create transaction record
    const transaction = new FastagTransaction({
      vehicleId: vehicle._id,
      txnId: `FT${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`,
      type: 'recharge',
      amount,
      method: 'wallet'
    });
    await transaction.save();

    res.json({
      success: true,
      message: 'FastTag recharged successfully',
      newBalance: vehicle.fastTag.balance,
      walletBalance: user.walletBalance,
      transaction
    });
  } catch (error) {
    console.error('Error recharging user FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Deactivate user's FastTag
const deactivateUserFastTag = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Get user's vehicles with FastTag
    const vehicles = await Vehicle.find({ userId, 'fastTag.tagId': { $exists: true } });

    if (vehicles.length === 0) {
      return res.status(400).json({ message: 'No FastTag found for user' });
    }

    // Use primary vehicle or first vehicle with FastTag
    const primaryVehicle = vehicles.find(v => v.isPrimary);
    const vehicle = primaryVehicle || vehicles[0];

    // Deactivate FastTag
    vehicle.fastTag.status = 'inactive';
    await vehicle.save();

    res.json({
      success: true,
      message: 'FastTag deactivated successfully'
    });
  } catch (error) {
    console.error('Error deactivating user FastTag:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user activities (recent bookings and parking history)
const getUserActivities = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Get recent bookings (last 10)
    const recentBookings = await SlotBooking.find({ userId })
      .populate('stationId', 'name location')
      .populate('vehicleId', 'number type')
      .sort({ createdAt: -1 })
      .limit(10);

    // Get recent parking history (last 10)
    const recentParking = await ParkingHistory.find({ userId })
      .populate('stationId', 'name location')
      .populate('vehicleId', 'number type')
      .sort({ createdAt: -1 })
      .limit(10);

    // Combine and sort by date
    const activities = [
      ...recentBookings.map(booking => ({
        id: booking._id,
        type: 'booking',
        action: `Booked parking at ${booking.stationId?.name || 'Station'}`,
        location: booking.stationId?.location || '',
        vehicle: booking.vehicleId ? `${booking.vehicleId.number} (${booking.vehicleId.type})` : 'Unknown vehicle',
        amount: booking.amountPaid,
        status: booking.status,
        date: booking.createdAt,
        bookingStartTime: booking.bookingStartTime,
        bookingEndTime: booking.bookingEndTime
      })),
      ...recentParking.map(parking => ({
        id: parking._id,
        type: 'parking',
        action: `Completed parking at ${parking.stationId?.name || 'Station'}`,
        location: parking.location || parking.stationId?.location || '',
        vehicle: parking.vehicleId ? `${parking.vehicleId.number} (${parking.vehicleId.type})` : 'Unknown vehicle',
        amount: parking.amountPaid,
        status: parking.status,
        date: parking.createdAt,
        startTime: parking.startTime,
        endTime: parking.endTime
      }))
    ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 20); // Get top 20 most recent

    res.json({
      success: true,
      activities
    });
  } catch (error) {
    console.error('Error fetching user activities:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user bookings (current and future bookings)
const getUserBookings = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user exists and has role 'user'
    const user = await User.findById(userId);
    if (!user || user.role !== 'user') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Fetch current and future bookings
    const bookings = await SlotBooking.find({ userId })
      .populate('stationId', 'name location address')
      .populate('vehicleId', 'number type')
      .populate('slotId', 'slotId type')
      .sort({ createdAt: -1 });

    const formattedBookings = bookings.map(booking => ({
      id: booking._id,
      stationId: booking.stationId?._id || '',
      stationName: booking.stationId?.name || 'Unknown Station',
      stationLocation: booking.stationId?.location || '',
      stationAddress: booking.stationId?.address || '',
      slotId: booking.slotId?.slotId || 'Unknown Slot',
      slotType: booking.slotId?.type || 'Unknown Type',
      vehicle: booking.vehicleId ? `${booking.vehicleId.number} (${booking.vehicleId.type})` : 'Unknown vehicle',
      bookingStartTime: booking.bookingStartTime,
      bookingEndTime: booking.bookingEndTime,
      amountPaid: booking.amountPaid,
      paymentMethod: booking.paymentMethod,
      paymentStatus: booking.paymentStatus,
      status: booking.status,
      reservationExpiresAt: booking.reservationExpiresAt,
      createdAt: booking.createdAt
    }));

    res.json({
      success: true,
      bookings: formattedBookings
    });
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getUserProfile,
  updateUserProfile,
  changeUserPassword,
  getUserDashboard,
  getUserVehicles,
  getUserPayments,
  addVehicle,
  setPrimaryVehicle,
  removeVehicle,
  addFavorite,
  removeFavorite,
  uploadProfileImage,
  getUserFastTag,
  applyForUserFastTag,
  rechargeUserFastTag,
  deactivateUserFastTag,
  getFastagTransactions,
  rechargeFastag,
  applyForFastag,
  getUserActivities,
  getUserBookings
};
