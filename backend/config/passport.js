console.log('GOOGLE_CLIENT_ID:', process.env.GOOGLE_CLIENT_ID);

const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const { Strategy: JwtStrategy, ExtractJwt } = require('passport-jwt');
const User = require('../models/User');

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (err) {
    done(err, null);
  }
});

// Google OAuth Strategy - only initialize if credentials are available
if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/auth/google/callback',
  }, async (accessToken, refreshToken, profile, done) => {
    try {
      let user = await User.findOne({ googleId: profile.id });
      if (!user) {
        // Check if the email already exists
        user = await User.findOne({ email: profile.emails[0].value });
        if (user) {
          // Update existing user with googleId
          user.googleId = profile.id;
          await user.save();
        } else {
          // Create new user
          user = await User.create({
            name: profile.displayName,
            email: profile.emails[0].value,
            googleId: profile.id,
            role: 'user',
          });
        }
      }
      done(null, user);
    } catch (err) {
      done(err, null);
    }
  }));
  console.log('Google OAuth strategy initialized');
} else {
  console.log('Google OAuth credentials not found - Google authentication disabled');
}

// JWT Strategy for API authentication
const opts = {
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  secretOrKey: 'default_jwt_secret_key',
};

const StoreAdminCredentials = require('../models/StoreAdminCredentials');

passport.use(new JwtStrategy(opts, async (jwt_payload, done) => {
  try {
    console.log('JWT payload received:', jwt_payload);
    let user;
    if (jwt_payload.role === 'store admin') {
      // For store admins, find in StoreAdminCredentials
      user = await StoreAdminCredentials.findById(jwt_payload.id).populate('stationId');
      console.log('Store admin user found:', user);
      if (user) {
        console.log('User stationId before attach:', user.stationId);
        // Attach stationId to the user object for easy access
        user.stationId = user.stationId._id || user.stationId;
        console.log('User stationId after attach:', user.stationId);
      } else {
        console.log('Store admin user not found for id:', jwt_payload.id);
      }
    } else {
      // For regular users and admins, find in User
      user = await User.findById(jwt_payload.id);
      console.log('Regular user found:', user);
    }
    if (user) {
      return done(null, user);
    }
    return done(null, false);
  } catch (err) {
    console.error('Error in JWT strategy:', err);
    return done(err, false);
  }
}));
