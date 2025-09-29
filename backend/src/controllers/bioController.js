const Astrologer = require('../models/Astrologer');

// @route   GET /api/bio/:astrologerId
// @desc    Get astrologer bio, certifications, and awards
// @access  Private
const getBio = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    
    const astrologer = await Astrologer.findById(astrologerId).select('bio certifications awards name');
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      data: {
        bio: astrologer.bio || '',
        certifications: astrologer.certifications || [],
        awards: astrologer.awards || [],
        name: astrologer.name
      }
    });
  } catch (error) {
    console.error('Get bio error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bio information'
    });
  }
};

// @route   PUT /api/bio/:astrologerId
// @desc    Update astrologer bio, certifications, and awards
// @access  Private
const updateBio = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { bio, certifications, awards } = req.body;
    
    // Validate input
    if (bio && bio.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Bio must be less than 1000 characters'
      });
    }

    if (certifications && !Array.isArray(certifications)) {
      return res.status(400).json({
        success: false,
        message: 'Certifications must be an array'
      });
    }

    if (awards && !Array.isArray(awards)) {
      return res.status(400).json({
        success: false,
        message: 'Awards must be an array'
      });
    }

    const updateData = {};
    if (bio !== undefined) updateData.bio = bio;
    if (certifications !== undefined) updateData.certifications = certifications;
    if (awards !== undefined) updateData.awards = awards;

    const astrologer = await Astrologer.findByIdAndUpdate(
      astrologerId,
      updateData,
      { new: true, runValidators: true }
    ).select('bio certifications awards name');

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      message: 'Bio information updated successfully',
      data: {
        bio: astrologer.bio || '',
        certifications: astrologer.certifications || [],
        awards: astrologer.awards || [],
        name: astrologer.name
      }
    });
  } catch (error) {
    console.error('Update bio error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update bio information'
    });
  }
};

// @route   POST /api/bio/:astrologerId/certification
// @desc    Add a new certification
// @access  Private
const addCertification = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { certification } = req.body;
    
    if (!certification || certification.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Certification is required'
      });
    }

    if (certification.length > 200) {
      return res.status(400).json({
        success: false,
        message: 'Certification must be less than 200 characters'
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Check if certification already exists
    if (astrologer.certifications.includes(certification.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Certification already exists'
      });
    }

    astrologer.certifications.push(certification.trim());
    await astrologer.save();

    res.json({
      success: true,
      message: 'Certification added successfully',
      data: {
        certifications: astrologer.certifications
      }
    });
  } catch (error) {
    console.error('Add certification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add certification'
    });
  }
};

// @route   POST /api/bio/:astrologerId/award
// @desc    Add a new award
// @access  Private
const addAward = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { award } = req.body;
    
    if (!award || award.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Award is required'
      });
    }

    if (award.length > 200) {
      return res.status(400).json({
        success: false,
        message: 'Award must be less than 200 characters'
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Check if award already exists
    if (astrologer.awards.includes(award.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Award already exists'
      });
    }

    astrologer.awards.push(award.trim());
    await astrologer.save();

    res.json({
      success: true,
      message: 'Award added successfully',
      data: {
        awards: astrologer.awards
      }
    });
  } catch (error) {
    console.error('Add award error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add award'
    });
  }
};

// @route   DELETE /api/bio/:astrologerId/certification/:index
// @desc    Remove a certification by index
// @access  Private
const removeCertification = async (req, res) => {
  try {
    const { astrologerId, index } = req.params;
    const certIndex = parseInt(index);
    
    if (isNaN(certIndex) || certIndex < 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid certification index'
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    if (certIndex >= astrologer.certifications.length) {
      return res.status(400).json({
        success: false,
        message: 'Certification index out of range'
      });
    }

    astrologer.certifications.splice(certIndex, 1);
    await astrologer.save();

    res.json({
      success: true,
      message: 'Certification removed successfully',
      data: {
        certifications: astrologer.certifications
      }
    });
  } catch (error) {
    console.error('Remove certification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove certification'
    });
  }
};

// @route   DELETE /api/bio/:astrologerId/award/:index
// @desc    Remove an award by index
// @access  Private
const removeAward = async (req, res) => {
  try {
    const { astrologerId, index } = req.params;
    const awardIndex = parseInt(index);
    
    if (isNaN(awardIndex) || awardIndex < 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid award index'
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    if (awardIndex >= astrologer.awards.length) {
      return res.status(400).json({
        success: false,
        message: 'Award index out of range'
      });
    }

    astrologer.awards.splice(awardIndex, 1);
    await astrologer.save();

    res.json({
      success: true,
      message: 'Award removed successfully',
      data: {
        awards: astrologer.awards
      }
    });
  } catch (error) {
    console.error('Remove award error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove award'
    });
  }
};

module.exports = {
  getBio,
  updateBio,
  addCertification,
  addAward,
  removeCertification,
  removeAward
};
