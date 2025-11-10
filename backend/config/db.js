const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGO_URI || "mongodb+srv://avinash:949367%40Sv@park-pro.rxeddmo.mongodb.net/";
    await mongoose.connect(mongoURI);
    console.log("✅ MongoDB Connected");
  } catch (err) {
    console.error("❌ Error connecting to MongoDB:", err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
