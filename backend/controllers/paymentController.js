const SlotBooking = require('../models/SlotBooking');
const StoreAdminCredentials = require('../models/StoreAdminCredentials');

// Get today's earnings for station admin's station
exports.getTodayEarnings = async (req, res) => {
  try {
    // Find admin and get stationId
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get successful payments for today
    const earnings = await SlotBooking.aggregate([
      {
        $match: {
          stationId: admin.stationId,
          paymentStatus: 'success',
          createdAt: { $gte: today, $lt: tomorrow }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amountPaid' },
          count: { $sum: 1 }
        }
      }
    ]);

    const result = earnings.length > 0 ? earnings[0] : { total: 0, count: 0 };
    res.json({ total: result.total, count: result.count });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get daily earnings for station admin's station
exports.getDailyEarnings = async (req, res) => {
  try {
    // Find admin and get stationId
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    // Get today's earnings
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const earnings = await SlotBooking.aggregate([
      {
        $match: {
          stationId: admin.stationId,
          paymentStatus: 'success',
          createdAt: { $gte: today, $lt: tomorrow }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amountPaid' }
        }
      }
    ]);

    const total = earnings.length > 0 ? earnings[0].total : 0;
    res.json({ total });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get monthly earnings for station admin's station
exports.getMonthlyEarnings = async (req, res) => {
  try {
    // Find admin and get stationId
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    // Get current month
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    const earnings = await SlotBooking.aggregate([
      {
        $match: {
          stationId: admin.stationId,
          paymentStatus: 'success',
          createdAt: { $gte: startOfMonth, $lt: endOfMonth }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amountPaid' }
        }
      }
    ]);

    const total = earnings.length > 0 ? earnings[0].total : 0;
    res.json({ total });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get payment method breakdown for station admin's station
exports.getPaymentBreakdown = async (req, res) => {
  try {
    // Find admin and get stationId
    const admin = await StoreAdminCredentials.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    // Get current month
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    const breakdown = await SlotBooking.aggregate([
      {
        $match: {
          stationId: admin.stationId,
          paymentStatus: 'success',
          createdAt: { $gte: startOfMonth, $lt: endOfMonth }
        }
      },
      {
        $group: {
          _id: '$paymentMethod',
          amount: { $sum: '$amountPaid' },
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          method: '$_id',
          amount: 1,
          count: 1,
          _id: 0
        }
      }
    ]);

    res.json(breakdown);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
