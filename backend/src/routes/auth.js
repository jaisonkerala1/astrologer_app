const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// @route   POST /api/auth/send-otp
// @desc    Send OTP to phone number
// @access  Public
router.post('/send-otp', authController.sendOTP);

// @route   POST /api/auth/verify-otp
// @desc    Verify OTP and login
// @access  Public
router.post('/verify-otp', authController.verifyOTP);

// @route   POST /api/auth/signup
// @desc    Signup new astrologer with OTP verification
// @access  Public
router.post('/signup', authController.signup);

// @route   POST /api/auth/refresh-token
// @desc    Refresh JWT token
// @access  Private
router.post('/refresh-token', require('../middleware/auth'), authController.refreshToken);

// @route   POST /api/auth/logout
// @desc    Logout user
// @access  Private
router.post('/logout', require('../middleware/auth'), authController.logout);

// @route   DELETE /api/auth/delete-account
// @desc    Permanently delete user account
// @access  Private
router.delete('/delete-account', require('../middleware/auth'), authController.deleteAccount);

module.exports = router;









