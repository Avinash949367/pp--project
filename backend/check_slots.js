const mongoose = require('mongoose');
const Slot = require('./models/Slot');

async function checkSlots() {
  try {
    await mongoose.connect('mongodb://localhost:27017/parkpro');
    const slots = await Slot.find({}).limit(5);
    console.log('Sample slots:', slots.map(s => ({
      id: s._id,
      slotId: s.slotId,
      type: s.type,
      availability: s.availability,
      stationId: s.stationId
    })));
    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
}

checkSlots();
