const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const auth = require('../middleware/auth');

// @route   GET /api/profile
// @desc    Get astrologer profile
// @access  Private
router.get('/', auth, profileController.getProfile);

// @route   PUT /api/profile
// @desc    Update astrologer profile
// @access  Private
router.put('/', auth, profileController.updateProfile);

// @route   POST /api/profile/upload-image
// @desc    Upload profile picture
// @access  Private
router.post('/upload-image', auth, profileController.uploadProfilePicture);

// @route   PUT /api/profile/specializations
// @desc    Update specializations
// @access  Private
router.put('/specializations', auth, profileController.updateSpecializations);

// @route   PUT /api/profile/languages
// @desc    Update languages
// @access  Private
router.put('/languages', auth, profileController.updateLanguages);

// @route   PUT /api/profile/rate
// @desc    Update rate per minute
// @access  Private
router.put('/rate', auth, profileController.updateRate);

module.exports = router;









