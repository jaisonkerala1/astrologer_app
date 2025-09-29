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

    // Professional field validation and sanitization
    const allowedFields = [
      'name', 'email', 'specializations', 'languages', 
      'experience', 'ratePerMinute', 'bio', 'awards', 'certificates'
    ];

    // Filter only allowed fields
    const filteredUpdates = {};
    allowedFields.forEach(field => {
      if (updates[field] !== undefined) {
        filteredUpdates[field] = updates[field];
      }
    });

    // Professional validation for bio fields
    if (filteredUpdates.bio !== undefined) {
      if (typeof filteredUpdates.bio !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Bio must be a text string'
        });
      }
      if (filteredUpdates.bio.length > 1000) {
        return res.status(400).json({
          success: false,
          message: 'Bio cannot exceed 1000 characters'
        });
      }
    }

    if (filteredUpdates.awards !== undefined) {
      if (typeof filteredUpdates.awards !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Awards must be a text string'
        });
      }
      if (filteredUpdates.awards.length > 500) {
        return res.status(400).json({
          success: false,
          message: 'Awards description cannot exceed 500 characters'
        });
      }
    }

    if (filteredUpdates.certificates !== undefined) {
      if (typeof filteredUpdates.certificates !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Certificates must be a text string'
        });
      }
      if (filteredUpdates.certificates.length > 500) {
        return res.status(400).json({
          success: false,
          message: 'Certificates description cannot exceed 500 characters'
        });
      }
    }

    // Update the astrologer in MongoDB with proper error handling
    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      { ...filteredUpdates, updatedAt: new Date() },
      { new: true, runValidators: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    console.log(`Profile updated for astrologer ID: ${astrologerId}`, {
      updatedFields: Object.keys(filteredUpdates)
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: astrologer
    });
  } catch (error) {
    console.error('Update profile error:', error);
    
    // Handle Mongoose validation errors professionally
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }

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

// Update bio fields specifically (UX-optimized endpoint)
const updateBioFields = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { bio, awards, certificates } = req.body;

    // Professional validation
    const validationErrors = [];

    if (bio !== undefined) {
      if (typeof bio !== 'string') {
        validationErrors.push('Bio must be a text string');
      } else if (bio.length > 1000) {
        validationErrors.push('Bio cannot exceed 1000 characters');
      }
    }

    if (awards !== undefined) {
      if (typeof awards !== 'string') {
        validationErrors.push('Awards must be a text string');
      } else if (awards.length > 500) {
        validationErrors.push('Awards description cannot exceed 500 characters');
      }
    }

    if (certificates !== undefined) {
      if (typeof certificates !== 'string') {
        validationErrors.push('Certificates must be a text string');
      } else if (certificates.length > 500) {
        validationErrors.push('Certificates description cannot exceed 500 characters');
      }
    }

    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }

    // Build update object with only provided fields
    const updateData = { updatedAt: new Date() };
    if (bio !== undefined) updateData.bio = bio.trim();
    if (awards !== undefined) updateData.awards = awards.trim();
    if (certificates !== undefined) updateData.certificates = certificates.trim();

    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    console.log(`Bio fields updated for astrologer ID: ${astrologerId}`, {
      updatedFields: Object.keys(updateData).filter(key => key !== 'updatedAt')
    });

    res.json({
      success: true,
      message: 'Bio fields updated successfully',
      data: {
        bio: astrologer.bio,
        awards: astrologer.awards,
        certificates: astrologer.certificates
      }
    });
  } catch (error) {
    console.error('Update bio fields error:', error);
    
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to update bio fields'
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  uploadProfilePicture,
  updateSpecializations,
  updateLanguages,
  updateRate,
  updateBioFields
};









