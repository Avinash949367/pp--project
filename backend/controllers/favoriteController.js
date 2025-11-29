const Favorite = require('../models/Favorite');

const addToFavorites = async (req, res) => {
  try {
    const { stationId } = req.body;
    const userId = req.user.id;

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({ userId, stationId });
    if (existingFavorite) {
      return res.status(400).json({ message: 'Station already in favorites' });
    }

    const favorite = new Favorite({ userId, stationId });
    await favorite.save();

    res.status(201).json({ message: 'Added to favorites' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

const removeFromFavorites = async (req, res) => {
  try {
    const { stationId } = req.params;
    const userId = req.user.id;

    await Favorite.findOneAndDelete({ userId, stationId });

    res.json({ message: 'Removed from favorites' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

const getUserFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const favorites = await Favorite.find({ userId }).populate('stationId');

    res.json({ favorites: favorites.map(fav => fav.stationId) });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

const checkFavoriteStatus = async (req, res) => {
  try {
    const { stationId } = req.params;
    const userId = req.user.id;

    const favorite = await Favorite.findOne({ userId, stationId });
    const isFavorite = !!favorite;

    res.json({ isFavorite });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  addToFavorites,
  removeFromFavorites,
  getUserFavorites,
  checkFavoriteStatus,
};
