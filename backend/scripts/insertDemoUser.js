const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

async function insertDemoUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/park-pro', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    // Clear existing demo user
    await User.deleteMany({ email: "demo@gmail.com" });
    console.log('Cleared existing demo user');

    // Insert demo user
    const hashedPassword = await bcrypt.hash('demo123', 10);
    const user = new User({
      name: 'Demo User',
      email: 'demo@gmail.com',
      password: hashedPassword,
      role: 'user',
      isConfirmed: true, // Confirmed
    });
    await user.save();
    console.log('Demo user created');

    console.log('Demo user insertion completed successfully!');
    console.log('Login credentials:');
    console.log('Email: demo@gmail.com');
    console.log('Password: demo123');

  } catch (error) {
    console.error('Error inserting demo user:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the script
insertDemoUser();
