const express = require('express');
const router = express.Router();
const bioController = require('../controllers/bioController');
const auth = require('../middleware/auth');

// @route   GET /api/bio/:astrologerId
// @desc    Get astrologer bio, certifications, and awards
// @access  Private
router.get('/:astrologerId', auth, bioController.getBio);

// @route   PUT /api/bio/:astrologerId
// @desc    Update astrologer bio, certifications, and awards
// @access  Private
router.put('/:astrologerId', auth, bioController.updateBio);

// @route   POST /api/bio/:astrologerId/certification
// @desc    Add a new certification
// @access  Private
router.post('/:astrologerId/certification', auth, bioController.addCertification);

// @route   POST /api/bio/:astrologerId/award
// @desc    Add a new award
// @access  Private
router.post('/:astrologerId/award', auth, bioController.addAward);

// @route   DELETE /api/bio/:astrologerId/certification/:index
// @desc    Remove a certification by index
// @access  Private
router.delete('/:astrologerId/certification/:index', auth, bioController.removeCertification);

// @route   DELETE /api/bio/:astrologerId/award/:index
// @desc    Remove an award by index
// @access  Private
router.delete('/:astrologerId/award/:index', auth, bioController.removeAward);

module.exports = router;
