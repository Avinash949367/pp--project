const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/parkpro', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

const addDemoVehicles = async () => {
    try {
        // Find a user (assuming there's a user with email 'user@example.com' or similar)
        // For demo purposes, let's find the first user
        const user = await User.findOne({ role: 'user' });
        if (!user) {
            console.log('No user found. Please create a user first.');
            return;
        }

        console.log('Adding vehicles for user:', user.email);

        // Clear existing vehicles for this user
        await Vehicle.deleteMany({ userId: user._id });
        console.log('Cleared existing vehicles');

        // Add demo vehicles
        const vehicles = [
            {
                userId: user._id,
                type: 'car',
                number: 'KA01AB1234',
                isPrimary: true
            },
            {
                userId: user._id,
                type: 'bike',
                number: 'KA02CD5678',
                isPrimary: false
            },
            {
                userId: user._id,
                type: 'ev',
                number: 'KA03EF9012',
                isPrimary: false
            }
        ];

        await Vehicle.insertMany(vehicles);
        console.log('Demo vehicles added successfully');
        console.log(`Added ${vehicles.length} vehicles for user ${user.email}`);

        // Show added vehicles
        const addedVehicles = await Vehicle.find({ userId: user._id });
        console.log('Current vehicles:', addedVehicles);

    } catch (error) {
        console.error('Error adding demo vehicles:', error);
    } finally {
        mongoose.connection.close();
    }
};

addDemoVehicles();
