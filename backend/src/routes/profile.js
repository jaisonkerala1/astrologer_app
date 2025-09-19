const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const auth = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = process.env.UPLOAD_PATH || 'uploads/';
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024 // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

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
router.post('/upload-image', auth, upload.single('profilePicture'), profileController.uploadProfilePicture);

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









