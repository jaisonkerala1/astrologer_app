const Astrologer = require('../models/Astrologer');
const path = require('path');
const fs = require('fs');

// Get profile
const getProfile = async (req, res) => {
  try {
    const { astrologerId } = req.user;

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      data: astrologer
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

    // Remove fields that shouldn't be updated directly
    delete updates.phone;
    delete updates.totalEarnings;
    delete updates.createdAt;
    delete updates.id;

    // Update the astrologer in MongoDB
    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      { ...updates, updatedAt: new Date() },
      { new: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    console.log(`Profile updated for astrologer ID: ${astrologerId}`);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: astrologer
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
      const oldImagePath = path.join(process.cwd(), 'uploads', path.basename(astrologer.profilePicture));
      if (fs.existsSync(oldImagePath)) {
        fs.unlinkSync(oldImagePath);
        console.log(`Deleted old profile picture: ${oldImagePath}`);
      }
    }

    // Update profile picture path
    const imagePath = req.file.path;
    const imageUrl = `/uploads/${req.file.filename}`;
    astrologer.profilePicture = imageUrl;
    astrologer.updatedAt = new Date();
    await astrologer.save();

    console.log(`Profile picture uploaded for astrologer ID: ${astrologerId}, URL: ${imageUrl}`);

    res.json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profilePicture: imageUrl
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
  uploadProfilePicture,
  updateSpecializations,
  updateLanguages,
  updateRate
};









