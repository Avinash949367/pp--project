const mongoose = require('mongoose');
const Counter = require('../models/Counter');

async function initCounterAtlas() {
  try {
    // Connect to MongoDB Atlas (same as in db.js)
    const mongoURI = process.env.MONGO_URI || "mongodb+srv://avinash:949367%40Sv@park-pro.rxeddmo.mongodb.net/?retryWrites=true&w=majority&appName=park-pro";
    await mongoose.connect(mongoURI);
    console.log('Connected to MongoDB Atlas');

    // Check if counter exists
    const existingCounter = await Counter.findOne({ name: 'fastagId' });
    if (existingCounter) {
      console.log('Counter already exists in Atlas:', existingCounter);
    } else {
      // Create counter
      const counter = new Counter({ name: 'fastagId', seq: 0 });
      await counter.save();
      console.log('Counter initialized in Atlas:', counter);
    }

    console.log('Counter initialization in Atlas completed successfully!');
  } catch (error) {
    console.error('Error initializing counter in Atlas:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the script
initCounterAtlas();
