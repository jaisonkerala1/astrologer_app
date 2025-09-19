const memoryStorage = require('../services/memoryStorage');
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

// Get profile
const getProfile = async (req, res) => {
  try {
    const { astrologerId } = req.user;

    const astrologer = memoryStorage.findAstrologerById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      data: {
        id: astrologer.id,
        phone: astrologer.phone,
        name: astrologer.name,
        email: astrologer.email,
        profilePicture: astrologer.profilePicture,
        specializations: astrologer.specializations,
        languages: astrologer.languages,
        experience: astrologer.experience,
        ratePerMinute: astrologer.ratePerMinute,
        isOnline: astrologer.isOnline,
        totalEarnings: astrologer.totalEarnings,
        createdAt: astrologer.createdAt,
        updatedAt: astrologer.updatedAt
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile'
    });
  }
};

// Update profile
const updateProfile = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const updates = req.body;

    // Find the astrologer
    const astrologer = memoryStorage.findAstrologerById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Remove fields that shouldn't be updated directly
    delete updates.phone;
    delete updates.totalEarnings;
    delete updates.createdAt;
    delete updates.id;

    // Update the astrologer data
    Object.assign(astrologer, updates, { updatedAt: new Date() });

    // Update in memory storage
    memoryStorage.astrologers.set(astrologerId, astrologer);

    console.log(`Profile updated for astrologer ID: ${astrologerId}`);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: astrologer.id,
        phone: astrologer.phone,
        name: astrologer.name,
        email: astrologer.email,
        profilePicture: astrologer.profilePicture,
        specializations: astrologer.specializations,
        languages: astrologer.languages,
        experience: astrologer.experience,
        ratePerMinute: astrologer.ratePerMinute,
        isOnline: astrologer.isOnline,
        totalEarnings: astrologer.totalEarnings,
        createdAt: astrologer.createdAt,
        updatedAt: astrologer.updatedAt
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile'
    });
  }
};

// Upload profile picture
const uploadProfilePicture = async (req, res) => {
  try {
    const { astrologerId } = req.user;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Delete old profile picture if exists
    if (astrologer.profilePicture) {
      const oldImagePath = path.join(process.cwd(), astrologer.profilePicture);
      if (fs.existsSync(oldImagePath)) {
        fs.unlinkSync(oldImagePath);
      }
    }

    // Update profile picture path
    const imagePath = req.file.path;
    astrologer.profilePicture = imagePath;
    astrologer.updatedAt = new Date();
    await astrologer.save();

    res.json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profilePicture: imagePath
      }
    });
  } catch (error) {
    console.error('Upload profile picture error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload profile picture'
    });
  }
};

// Update specializations
const updateSpecializations = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { specializations } = req.body;

    if (!Array.isArray(specializations)) {
      return res.status(400).json({
        success: false,
        message: 'Specializations must be an array'
      });
    }

    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      { specializations, updatedAt: new Date() },
      { new: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      message: 'Specializations updated successfully',
      data: {
        specializations: astrologer.specializations
      }
    });
  } catch (error) {
    console.error('Update specializations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update specializations'
    });
  }
};

// Update languages
const updateLanguages = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { languages } = req.body;

    if (!Array.isArray(languages)) {
      return res.status(400).json({
        success: false,
        message: 'Languages must be an array'
      });
    }

    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      { languages, updatedAt: new Date() },
      { new: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      message: 'Languages updated successfully',
      data: {
        languages: astrologer.languages
      }
    });
  } catch (error) {
    console.error('Update languages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update languages'
    });
  }
};

// Update rate
const updateRate = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { ratePerMinute } = req.body;

    if (!ratePerMinute || ratePerMinute < 0) {
      return res.status(400).json({
        success: false,
        message: 'Rate per minute must be a positive number'
      });
    }

    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      { ratePerMinute, updatedAt: new Date() },
      { new: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      message: 'Rate updated successfully',
      data: {
        ratePerMinute: astrologer.ratePerMinute
      }
    });
  } catch (error) {
    console.error('Update rate error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update rate'
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  uploadProfilePicture: [upload.single('image'), uploadProfilePicture],
  updateSpecializations,
  updateLanguages,
  updateRate
};









