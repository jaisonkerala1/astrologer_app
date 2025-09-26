const express = require('express');
const router = express.Router();
const responseTimeController = require('../controllers/responseTimeController');
const auth = require('../middleware/auth');

// @route   GET /api/response-time/stats
// @desc    Get response time statistics
// @access  Private
router.get('/stats', auth, responseTimeController.getResponseTimeStats);

// @route   POST /api/response-time/update
// @desc    Update response time for a consultation
// @access  Private
router.post('/update', auth, responseTimeController.updateResponseTime);

// @route   GET /api/response-time/history
// @desc    Get response time history with pagination
// @access  Private
router.get('/history', auth, responseTimeController.getResponseTimeHistory);

// @route   GET /api/response-time/analytics
// @desc    Get response time analytics and trends
// @access  Private
router.get('/analytics', auth, responseTimeController.getResponseTimeAnalytics);

module.exports = router;
