const User = require('../models/User');

// Get all users for admin view
const getAllUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select('-password -confirmationToken -otpExpiry')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      users: users.map(user => ({
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        role: user.role,
        membershipStatus: user.membershipStatus,
        isConfirmed: user.isConfirmed,
        walletBalance: user.walletBalance,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }))
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user by ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id).select('-password -confirmationToken -otpExpiry');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        role: user.role,
        membershipStatus: user.membershipStatus,
        isConfirmed: user.isConfirmed,
        walletBalance: user.walletBalance,
        vehicle: user.vehicle,
        savedVehicles: user.savedVehicles,
        preferredSpots: user.preferredSpots,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get user by email
const getUserByEmail = async (req, res) => {
  try {
    const { email } = req.params;
    const user = await User.findOne({ email }).select('-password -confirmationToken -otpExpiry');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      profileImage: user.profileImage,
      role: user.role,
      membershipStatus: user.membershipStatus,
      isConfirmed: user.isConfirmed,
      walletBalance: user.walletBalance,
      vehicle: user.vehicle,
      savedVehicles: user.savedVehicles,
      preferredSpots: user.preferredSpots,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update user (admin only)
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, role, membershipStatus, isConfirmed } = req.body;

    // Check if email is already taken by another user
    if (email) {
      const existingUser = await User.findOne({ email, _id: { $ne: id } });
      if (existingUser) {
        return res.status(400).json({ message: 'Email already in use' });
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      id,
      { name, email, phone, role, membershipStatus, isConfirmed },
      { new: true, runValidators: true }
    ).select('-password -confirmationToken -otpExpiry');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      message: 'User updated successfully',
      user: {
        id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        phone: updatedUser.phone || '',
        role: updatedUser.role,
        membershipStatus: updatedUser.membershipStatus,
        isConfirmed: updatedUser.isConfirmed
      }
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Delete user (admin only)
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    const deletedUser = await User.findByIdAndDelete(id);

    if (!deletedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Ban user (admin only) - revoke all access
const banUser = async (req, res) => {
  try {
    const { id } = req.params;

    const bannedUser = await User.findByIdAndUpdate(
      id,
      {
        isConfirmed: false,
        role: 'banned'
      },
      { new: true }
    );

    if (!bannedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      message: 'User banned successfully',
      user: {
        id: bannedUser._id,
        name: bannedUser.name,
        email: bannedUser.email,
        role: bannedUser.role,
        isConfirmed: bannedUser.isConfirmed
      }
    });
  } catch (error) {
    console.error('Error banning user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Disable user temporarily (admin only)
const disableUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { duration } = req.body; // duration in hours

    if (!duration || ![24, 48].includes(duration)) {
      return res.status(400).json({ message: 'Invalid duration. Must be 24 or 48 hours.' });
    }

    const disableUntil = new Date();
    disableUntil.setHours(disableUntil.getHours() + duration);

    const disabledUser = await User.findByIdAndUpdate(
      id,
      {
        isConfirmed: false,
        disabledUntil: disableUntil
      },
      { new: true }
    );

    if (!disabledUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      message: `User disabled for ${duration} hours successfully`,
      user: {
        id: disabledUser._id,
        name: disabledUser.name,
        email: disabledUser.email,
        isConfirmed: disabledUser.isConfirmed,
        disabledUntil: disabledUser.disabledUntil
      }
    });
  } catch (error) {
    console.error('Error disabling user:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  getUserByEmail,
  updateUser,
  deleteUser,
  banUser,
  disableUser
};
