require('dotenv').config();  // make sure dotenv is loaded

const express = require('express');
const path = require('path');
const http = require('http');
const connectDB = require('./config/db');
const passport = require('passport');
const session = require('express-session');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const registerRoutes = require('./routes/registerRoutes');
const stationRoutes = require('./routes/stationRoutes');
const slotRoutes = require('./routes/slotRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
require('./config/passport'); // Passport config

const bcrypt = require('bcryptjs');
const User = require('./models/User');

const app = express();

// Connect to MongoDB
connectDB(); // Force restart

// Create default admin user if not exists
const createAdminUser = async () => {
  try {
    const adminUser = await User.findOne({ email: 'admin1@gmail.com' });
    if (!adminUser) {
      const hashedPassword = await bcrypt.hash('adminlogin', 10);
      await User.create({
        name: 'admin',
        email: 'admin1@gmail.com',
        password: hashedPassword,
        role: 'admin',
      });
      console.log('Default admin user created');
    } else {
      console.log('Admin user already exists');
    }
  } catch (err) {
    console.error('Error creating admin user:', err.message);
  }
};

createAdminUser();

app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Referrer']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: process.env.SESSION_SECRET || 'secretkey',
  resave: false,
  saveUninitialized: false,
}));
app.use(passport.initialize());
app.use(passport.session());

// Serve static files from the frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

// Routes
app.use('/', authRoutes);
app.use('/api/registrations', registerRoutes);
app.use('/api', stationRoutes);

const mediaRoutes = require('./routes/mediaRoutes');
app.use('/api/media', mediaRoutes);

const userProfileRoutes = require('./routes/userProfileRoutes');
const userRoutes = require('./routes/userRoutes');
const contactRoutes = require('./routes/contactRoutes');
const fastagRoutes = require('./routes/fastagRoutes');

// Import cleanup function
const cleanupExpiredReservations = require('./scripts/cleanupExpiredReservations');

// Run cleanup every 5 minutes (300000 ms)
setInterval(cleanupExpiredReservations, 5 * 60 * 1000);

app.use('/api/user', userProfileRoutes);
app.use('/api', userRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/slots', slotRoutes);
app.use('/api/reviews', reviewRoutes);  // Added review routes
app.use('/api/fastag', fastagRoutes);
app.use('/api/notifications', notificationRoutes);

// Proxy route for AI chat
app.post('/api/chat', (req, res) => {
  const body = JSON.stringify(req.body);
  const options = {
    hostname: 'localhost',
    port: 8000,
    path: '/chat',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
    res.status(500).send('Proxy error');
  });

  // Send the request body as JSON
  proxyReq.write(body);
  proxyReq.end();
});

// Start the server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
