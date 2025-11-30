const axios = require('axios');

async function checkSlotData() {
  try {
    const response = await axios.get('http://localhost:5000/api/slots/station/STN46559311SD');
    console.log('Slot data structure:');
    console.log('Total slots:', response.data.length);
    if (response.data.length > 0) {
      console.log('First slot sample:');
      console.log(JSON.stringify(response.data[0], null, 2));
    }
  } catch (error) {
    console.log('Error fetching slots:', error.message);
  }
}

checkSlotData();
