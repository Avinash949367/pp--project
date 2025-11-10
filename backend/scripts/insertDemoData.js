const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Station = require('../models/Station');
const StoreAdminCredentials = require('../models/StoreAdminCredentials');

// Demo data
const demoStation = {
  name: "Park Pro – City Center",
  location: "MG Road, Bengaluru",
  capacity: "50",
  mobile: "9876543210",
  email: "demo@parkpro.com",
  maplink: "https://maps.google.com/?q=MG+Road+Bengaluru",
  apartment: "City Center Mall",
  size: "Large",
  facilities: "EV Charging, Covered Parking, Security, CCTV",
  status: "active"
};

async function insertDemoData() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/parkpro', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    // Clear existing demo data
    await Station.deleteMany({ email: "demo@parkpro.com" });
    await StoreAdminCredentials.deleteMany({ email: "demo@parkpro.com" });
    console.log('Cleared existing demo data');

    // Insert demo station
    const station = new Station(demoStation);
    const savedStation = await station.save();
    console.log('Demo station created:', savedStation._id);

    // Insert demo credentials
    const hashedPassword = await bcrypt.hash('demo', 10);
    const credentials = new StoreAdminCredentials({
      stationId: savedStation._id,
      email: "demo@parkpro.com",
      password: hashedPassword
    });
    await credentials.save();
    console.log('Demo credentials created');

    console.log('Demo data insertion completed successfully!');
    console.log('Login credentials:');
    console.log('Email: demo@parkpro.com');
    console.log('Password: demo');
    console.log('Station ID: ST001');

  } catch (error) {
    console.error('Error inserting demo data:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the script
insertDemoData();
