const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const auth = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Astrologer = require('../models/Astrologer');
const ApprovalRequest = require('../models/ApprovalRequest');
const Review = require('../models/Review');
const Consultation = require('../models/Consultation');

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

// @route   PUT /api/profile/bio
// @desc    Update bio, awards, and certificates fields
// @access  Private
router.put('/bio', auth, profileController.updateBioFields);

// @route   POST /api/profile/verification/request
// @desc    Request verification badge
// @access  Private
router.post('/verification/request', auth, async (req, res) => {
  try {
    const { astrologerId } = req.user;

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Check if already verified
    if (astrologer.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Astrologer is already verified'
      });
    }

    // Check if there's already a pending request
    const existingRequest = await ApprovalRequest.findOne({
      astrologerId,
      requestType: 'verification_badge',
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending verification request'
      });
    }

    // Validation requirements
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const monthsSinceSignup = (new Date() - new Date(astrologer.createdAt)) / (1000 * 60 * 60 * 24 * 30);

    // Get astrologer stats
    const [consultationsCount, reviewStats] = await Promise.all([
      Consultation.countDocuments({ astrologerId }),
      Review.aggregate([
        { $match: { astrologerId } },
        {
          $group: {
            _id: null,
            avgRating: { $avg: '$rating' },
            totalReviews: { $sum: 1 }
          }
        }
      ])
    ]);

    const ratingData = reviewStats[0] || { avgRating: 0, totalReviews: 0 };
    const avgRating = ratingData.avgRating || 0;

    // Check requirements
    const requirements = {
      experience: monthsSinceSignup >= 6,
      rating: avgRating >= 4.5,
      consultations: consultationsCount >= 50,
      profileComplete: !!(astrologer.bio && astrologer.bio.trim() && 
                         astrologer.awards && astrologer.awards.trim() && 
                         astrologer.certificates && astrologer.certificates.trim())
    };

    const allMet = Object.values(requirements).every(v => v === true);

    if (!allMet) {
      const missing = [];
      if (!requirements.experience) missing.push('At least 6 months on platform');
      if (!requirements.rating) missing.push('Average rating of 4.5 or higher');
      if (!requirements.consultations) missing.push('At least 50 completed consultations');
      if (!requirements.profileComplete) missing.push('Complete profile (bio, awards, certificates)');

      return res.status(400).json({
        success: false,
        message: 'Verification requirements not met',
        requirements: {
          ...requirements,
          missing
        },
        current: {
          monthsOnPlatform: Math.round(monthsSinceSignup * 10) / 10,
          avgRating: Math.round(avgRating * 10) / 10,
          consultationsCount,
          profileComplete: requirements.profileComplete
        }
      });
    }

    // Create approval request
    const approvalRequest = new ApprovalRequest({
      astrologerId,
      astrologerName: astrologer.name,
      astrologerEmail: astrologer.email,
      astrologerPhone: astrologer.phone,
      astrologerAvatar: astrologer.profilePicture,
      requestType: 'verification_badge',
      status: 'pending',
      submittedAt: new Date(),
      astrologerData: {
        experience: astrologer.experience,
        specializations: astrologer.specializations || [],
        consultationsCount,
        rating: Math.round(avgRating * 10) / 10
      }
    });

    await approvalRequest.save();

    // Update astrologer verification status
    astrologer.verificationStatus = 'pending';
    astrologer.verificationSubmittedAt = new Date();
    await astrologer.save();

    res.status(201).json({
      success: true,
      data: approvalRequest,
      message: 'Verification request submitted successfully'
    });
  } catch (error) {
    console.error('Verification request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit verification request',
      error: error.message
    });
  }
});

// @route   GET /api/profile/verification/status
// @desc    Get verification status
// @access  Private
router.get('/verification/status', auth, async (req, res) => {
  try {
    const { astrologerId } = req.user;

    const astrologer = await Astrologer.findById(astrologerId).select(
      'isVerified verificationStatus verificationSubmittedAt verificationApprovedAt verificationRejectionReason'
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Get latest approval request if exists
    const latestRequest = await ApprovalRequest.findOne({
      astrologerId,
      requestType: 'verification_badge'
    })
      .sort({ submittedAt: -1 })
      .select('status submittedAt reviewedAt rejectionReason notes');

    res.json({
      success: true,
      data: {
        isVerified: astrologer.isVerified,
        verificationStatus: astrologer.verificationStatus,
        verificationSubmittedAt: astrologer.verificationSubmittedAt,
        verificationApprovedAt: astrologer.verificationApprovedAt,
        verificationRejectionReason: astrologer.verificationRejectionReason,
        latestRequest: latestRequest || null
      }
    });
  } catch (error) {
    console.error('Get verification status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get verification status',
      error: error.message
    });
  }
});

module.exports = router;









