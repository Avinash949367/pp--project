const express = require('express');
const router = express.Router();
const favoriteController = require('../controllers/favoriteController');
const auth = require('../middleware/auth');

console.log('Favorite routes loaded');

// All favorite routes require authentication
router.use(auth);

// Add station to favorites
router.post('/add', favoriteController.addToFavorites);

// Remove station from favorites
router.delete('/:stationId', favoriteController.removeFromFavorites);

// Get user's favorite stations
router.get('/', favoriteController.getUserFavorites);

// Check if station is favorited
router.get('/check/:stationId', favoriteController.checkFavoriteStatus);

module.exports = router;
