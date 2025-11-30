const Station = require('../models/Station');
const StoreAdminCredentials = require('../models/StoreAdminCredentials');
const bcrypt = require('bcryptjs');

// Get all stations
exports.getAllStations = async (req, res) => {
  try {
    const stations = await Station.find();
    res.json(stations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get station by ID
exports.getStationById = async (req, res) => {
  try {
    const station = await Station.findById(req.params.id);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json(station);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Search stations by city
exports.searchStationsByCity = async (req, res) => {
  try {
    const stations = await Station.find({ city: new RegExp(req.params.city, 'i') });
    res.json({ success: true, stations });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get stations by status
exports.getStationsByStatus = async (req, res) => {
  try {
    const stations = await Station.find({ status: req.params.status });
    res.json(stations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Create a new station
exports.createStation = async (req, res) => {
  try {
    const station = new Station(req.body);
    await station.save();
    res.status(201).json(station);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update station status
exports.updateStationStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const station = await Station.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json(station);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get station stats
exports.getStationStats = async (req, res) => {
  try {
    const totalStations = await Station.countDocuments();
    const activeStations = await Station.countDocuments({ status: 'active' });
    const inactiveStations = await Station.countDocuments({ status: 'inactive' });
    res.json({
      totalStations,
      activeStations,
      inactiveStations
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get GPS structure of a station
exports.getStationGPSStructure = async (req, res) => {
  try {
    const station = await Station.findById(req.params.stationId);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json(station.gpsStructure || {});
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Save GPS structure of a station
exports.saveStationGPSStructure = async (req, res) => {
  try {
    const station = await Station.findByIdAndUpdate(
      req.params.stationId,
      { gpsStructure: req.body },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json(station.gpsStructure);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Submit station for approval
exports.submitStationForApproval = async (req, res) => {
  try {
    const station = await Station.findByIdAndUpdate(
      req.params.stationId,
      { gpsMappingStatus: 'submitted_for_approval' },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({ message: 'Station submitted for approval' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Approve station
exports.approveStation = async (req, res) => {
  try {
    const station = await Station.findByIdAndUpdate(
      req.params.stationId,
      {
        gpsMappingStatus: 'approved',
        approvedAt: new Date(),
        approvedBy: req.user ? req.user.id : 'admin'
      },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({ message: 'Station approved' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Reject station
exports.rejectStation = async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const station = await Station.findByIdAndUpdate(
      req.params.stationId,
      {
        gpsMappingStatus: 'rejected',
        rejectedAt: new Date(),
        rejectionReason
      },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({ message: 'Station rejected' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Toggle public visibility
exports.togglePublicVisibility = async (req, res) => {
  try {
    const station = await Station.findById(req.params.stationId);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    station.publicVisibility = !station.publicVisibility;
    await station.save();
    res.json({ publicVisibility: station.publicVisibility });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get stations by mapping status
exports.getStationsByMappingStatus = async (req, res) => {
  try {
    const stations = await Station.find({ gpsMappingStatus: req.params.status });
    res.json(stations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get station settings (for authenticated station admin)
exports.getStationSettings = async (req, res) => {
  try {
    // Assuming req.user.id is the stationId
    const station = await Station.findById(req.user.id);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({
      openAt: station.openAt,
      closeAt: station.closeAt,
      publicVisibility: station.publicVisibility
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Save station settings (for authenticated station admin)
exports.saveStationSettings = async (req, res) => {
  try {
    const { openAt, closeAt, publicVisibility } = req.body;
    const station = await Station.findByIdAndUpdate(
      req.user.id,
      { openAt, closeAt, publicVisibility },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({ message: 'Settings saved' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get station for authenticated station admin
exports.getMyStation = async (req, res) => {
  try {
    // Find StoreAdminCredentials by _id (req.user.id is StoreAdminCredentials id)
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    // Find the station using the stationId from admin credentials
    const station = await Station.findById(admin.stationId);
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }

    res.json(station);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get station admin profile
exports.getStationAdminProfile = async (req, res) => {
  try {
    // Find StoreAdminCredentials by _id (req.user.id is StoreAdminCredentials id)
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }
    res.json({
      name: admin.name,
      email: admin.email,
      phone: admin.phone
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update station admin profile
exports.updateStationAdminProfile = async (req, res) => {
  try {
    const { name, phone } = req.body;
    const admin = await StoreAdminCredentials.findByIdAndUpdate(
      req.user.id,
      { name, phone },
      { new: true }
    );
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }
    res.json({ message: 'Profile updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Change station admin password
exports.changeStationAdminPassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }
    const isMatch = await bcrypt.compare(currentPassword, admin.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    admin.password = hashedPassword;
    await admin.save();
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Set station working hours (admin API)
exports.setStationHours = async (req, res) => {
  try {
    const { openAt, closeAt } = req.body;
    const station = await Station.findByIdAndUpdate(
      req.params.id,
      { openAt, closeAt },
      { new: true }
    );
    if (!station) {
      return res.status(404).json({ message: 'Station not found' });
    }
    res.json({ message: 'Working hours updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
