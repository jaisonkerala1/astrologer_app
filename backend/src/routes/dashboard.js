const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const auth = require('../middleware/auth');

// @route   GET /api/dashboard/stats
// @desc    Get dashboard statistics
// @access  Private
router.get('/stats', auth, dashboardController.getDashboardStats);

// @route   PUT /api/dashboard/status
// @desc    Update online/offline status
// @access  Private
router.put('/status', auth, dashboardController.updateOnlineStatus);

// @route   GET /api/dashboard/sessions
// @desc    Get recent sessions
// @access  Private
router.get('/sessions', auth, dashboardController.getRecentSessions);

module.exports = router;









