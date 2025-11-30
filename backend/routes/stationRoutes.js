const express = require('express');
const router = express.Router();
const passport = require('passport');
const stationController = require('../controllers/stationController');

// Station routes
router.get('/stations', stationController.getAllStations);
router.get('/stations/me', passport.authenticate('jwt', { session: false }), stationController.getMyStation);
router.get('/stations/:id', stationController.getStationById);
router.get('/stations/search/:city', stationController.searchStationsByCity);
router.get('/stations/status/:status', stationController.getStationsByStatus);
router.post('/stations', stationController.createStation);
router.patch('/stations/:id/status', stationController.updateStationStatus);
router.get('/stations/stats', stationController.getStationStats);

// GPS Structure routes
router.get('/stations/:stationId/gps-structure', stationController.getStationGPSStructure);
router.put('/stations/:stationId/gps-structure', stationController.saveStationGPSStructure);
router.post('/stations/:stationId/submit-for-approval', stationController.submitStationForApproval);
router.post('/stations/:stationId/approve', stationController.approveStation);
router.post('/stations/:stationId/reject', stationController.rejectStation);
router.patch('/stations/:stationId/visibility', stationController.togglePublicVisibility);
router.get('/stations/mapping-status/:status', stationController.getStationsByMappingStatus);

// Station Settings routes
router.get('/stations/settings', passport.authenticate('jwt', { session: false }), stationController.getStationSettings);
router.post('/stations/settings', passport.authenticate('jwt', { session: false }), stationController.saveStationSettings);

// Station Admin Profile routes
router.get('/stations/admin/profile', passport.authenticate('jwt', { session: false }), stationController.getStationAdminProfile);
router.put('/stations/admin/profile', passport.authenticate('jwt', { session: false }), stationController.updateStationAdminProfile);
router.put('/stations/admin/change-password', passport.authenticate('jwt', { session: false }), stationController.changeStationAdminPassword);

// Admin API to set station working hours
router.post('/admin/stations/:id/hours', passport.authenticate('jwt', { session: false }), stationController.setStationHours);

module.exports = router;
