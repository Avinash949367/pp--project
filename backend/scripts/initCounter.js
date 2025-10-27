const mongoose = require('mongoose');
const Counter = require('../models/Counter');

async function initCounter() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/parkpro', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    // Check if counter exists
    const existingCounter = await Counter.findOne({ name: 'fastagId' });
    if (existingCounter) {
      console.log('Counter already exists:', existingCounter);
    } else {
      // Create counter
      const counter = new Counter({ name: 'fastagId', seq: 0 });
      await counter.save();
      console.log('Counter initialized:', counter);
    }

    console.log('Counter initialization completed successfully!');
  } catch (error) {
    console.error('Error initializing counter:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the script
initCounter();
