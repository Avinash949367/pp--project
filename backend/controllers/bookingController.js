const SlotBooking = require('../models/SlotBooking');
const StoreAdminCredentials = require('../models/StoreAdminCredentials');
const Station = require('../models/Station');

// Get current bookings for station admin
exports.getCurrentBookings = async (req, res) => {
  try {
    // Get user from JWT
    if (!req.user || req.user.role !== 'store admin') {
      return res.status(403).json({ message: 'Access denied. Station admin only.' });
    }

    // Find station for this admin
    const credentials = await StoreAdminCredentials.findOne({ email: req.user.email });
    if (!credentials) {
      return res.status(404).json({ message: 'Station admin credentials not found' });
    }

    const station = await Station.findById(credentials.stationId);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }

    // Get current active bookings
    const currentBookings = await SlotBooking.find({
      stationId: station._id,
      status: { $in: ['active', 'confirmed'] }
    })
    .populate('userId', 'name email')
    .populate('vehicleId', 'number')
    .populate('slotId', 'slotId type')
    .sort({ bookingStartTime: 1 });

    res.json(currentBookings);
  } catch (error) {
    console.error('Error fetching current bookings:', error);
    res.status(500).json({ message: 'Error fetching current bookings', error: error.message });
  }
};

// Get all bookings for station admin
exports.getAllBookings = async (req, res) => {
  try {
    // Get user from JWT
    if (!req.user || req.user.role !== 'store admin') {
      return res.status(403).json({ message: 'Access denied. Station admin only.' });
    }

    // Find station for this admin
    const credentials = await StoreAdminCredentials.findOne({ email: req.user.email });
    if (!credentials) {
      return res.status(404).json({ message: 'Station admin credentials not found' });
    }

    const station = await Station.findById(credentials.stationId);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }

    // Get all bookings for the station
    const allBookings = await SlotBooking.find({
      stationId: station._id
    })
    .populate('userId', 'name email')
    .populate('vehicleId', 'number')
    .populate('slotId', 'slotId type')
    .sort({ createdAt: -1 });

    res.json(allBookings);
  } catch (error) {
    console.error('Error fetching all bookings:', error);
    res.status(500).json({ message: 'Error fetching all bookings', error: error.message });
  }
};
