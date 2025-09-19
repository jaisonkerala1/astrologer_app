const Consultation = require('../models/Consultation');
const Astrologer = require('../models/Astrologer');
const mongoose = require('mongoose');

// Get all consultations for an astrologer
const getConsultations = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { 
      status, 
      type, 
      startDate, 
      endDate, 
      page = 1, 
      limit = 20,
      sortBy = 'scheduledTime',
      sortOrder = 'asc'
    } = req.query;

    // Validate astrologerId
    if (!mongoose.Types.ObjectId.isValid(astrologerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid astrologer ID'
      });
    }

    // Build filter criteria
    const filter = { astrologerId };

    if (status) {
      filter.status = status;
    }

    if (type) {
      filter.type = type;
    }

    if (startDate || endDate) {
      filter.scheduledTime = {};
      if (startDate) filter.scheduledTime.$gte = new Date(startDate);
      if (endDate) filter.scheduledTime.$lte = new Date(endDate);
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query
    const consultations = await Consultation.find(filter)
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .populate('astrologerId', 'name phone email');

    const total = await Consultation.countDocuments(filter);

    res.status(200).json({
      success: true,
      data: {
        consultations,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching consultations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch consultations',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get a single consultation by ID
const getConsultationById = async (req, res) => {
  try {
    const { consultationId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    const consultation = await Consultation.findById(consultationId)
      .populate('astrologerId', 'name phone email');

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.status(200).json({
      success: true,
      data: consultation
    });

  } catch (error) {
    console.error('Error fetching consultation:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch consultation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Create a new consultation
const createConsultation = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const consultationData = req.body;

    // Validate astrologerId
    if (!mongoose.Types.ObjectId.isValid(astrologerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid astrologer ID'
      });
    }

    // Check if astrologer exists
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Validate required fields
    const requiredFields = ['clientName', 'clientPhone', 'scheduledTime', 'duration', 'type'];
    for (const field of requiredFields) {
      if (!consultationData[field]) {
        return res.status(400).json({
          success: false,
          message: `${field} is required`
        });
      }
    }

    // Validate scheduled time is in the future
    const scheduledTime = new Date(consultationData.scheduledTime);
    if (scheduledTime <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Scheduled time must be in the future'
      });
    }

    // Set default amount if not provided
    if (!consultationData.amount) {
      consultationData.amount = consultationData.duration * (astrologer.ratePerMinute || 10);
    }

    // Create consultation
    const consultation = new Consultation({
      ...consultationData,
      astrologerId,
      isManual: true,
      source: 'app'
    });

    await consultation.save();

    // Populate astrologer data
    await consultation.populate('astrologerId', 'name phone email');

    res.status(201).json({
      success: true,
      message: 'Consultation created successfully',
      data: consultation
    });

  } catch (error) {
    console.error('Error creating consultation:', error);
    
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to create consultation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Update a consultation
const updateConsultation = async (req, res) => {
  try {
    const { consultationId } = req.params;
    const updateData = req.body;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    // Check if consultation exists
    const consultation = await Consultation.findById(consultationId);
    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    // Prevent updating completed consultations
    if (consultation.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot update completed consultation'
      });
    }

    // Validate scheduled time if being updated
    if (updateData.scheduledTime) {
      const scheduledTime = new Date(updateData.scheduledTime);
      if (scheduledTime <= new Date()) {
        return res.status(400).json({
          success: false,
          message: 'Scheduled time must be in the future'
        });
      }
    }

    // Update consultation
    const updatedConsultation = await Consultation.findByIdAndUpdate(
      consultationId,
      updateData,
      { new: true, runValidators: true }
    ).populate('astrologerId', 'name phone email');

    res.status(200).json({
      success: true,
      message: 'Consultation updated successfully',
      data: updatedConsultation
    });

  } catch (error) {
    console.error('Error updating consultation:', error);
    
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to update consultation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Update consultation status
const updateConsultationStatus = async (req, res) => {
  try {
    const { consultationId } = req.params;
    const { status, notes, cancelledBy, cancellationReason } = req.body;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    // Validate status
    const validStatuses = ['scheduled', 'inProgress', 'completed', 'cancelled', 'noShow'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status'
      });
    }

    const consultation = await Consultation.findById(consultationId);
    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    // Update status with additional data
    const updateData = { status };
    
    if (status === 'completed') {
      updateData.completedAt = new Date();
      if (notes) updateData.notes = notes;
    } else if (status === 'cancelled') {
      updateData.cancelledAt = new Date();
      updateData.cancelledBy = cancelledBy || 'astrologer';
      if (cancellationReason) updateData.cancellationReason = cancellationReason;
    }

    const updatedConsultation = await Consultation.findByIdAndUpdate(
      consultationId,
      updateData,
      { new: true, runValidators: true }
    ).populate('astrologerId', 'name phone email');

    res.status(200).json({
      success: true,
      message: 'Consultation status updated successfully',
      data: updatedConsultation
    });

  } catch (error) {
    console.error('Error updating consultation status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update consultation status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Delete a consultation
const deleteConsultation = async (req, res) => {
  try {
    const { consultationId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    const consultation = await Consultation.findById(consultationId);
    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    // Prevent deleting completed consultations
    if (consultation.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete completed consultation'
      });
    }

    await Consultation.findByIdAndDelete(consultationId);

    res.status(200).json({
      success: true,
      message: 'Consultation deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting consultation:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete consultation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get upcoming consultations
const getUpcomingConsultations = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { limit = 10 } = req.query;

    if (!mongoose.Types.ObjectId.isValid(astrologerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid astrologer ID'
      });
    }

    const consultations = await Consultation.getUpcomingConsultations(
      astrologerId, 
      parseInt(limit)
    );

    res.status(200).json({
      success: true,
      data: consultations
    });

  } catch (error) {
    console.error('Error fetching upcoming consultations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch upcoming consultations',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get today's consultations
const getTodaysConsultations = async (req, res) => {
  try {
    const { astrologerId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(astrologerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid astrologer ID'
      });
    }

    const consultations = await Consultation.getTodaysConsultations(astrologerId);

    res.status(200).json({
      success: true,
      data: consultations
    });

  } catch (error) {
    console.error('Error fetching today\'s consultations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch today\'s consultations',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get consultation statistics
const getConsultationStats = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { startDate, endDate } = req.query;

    if (!mongoose.Types.ObjectId.isValid(astrologerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid astrologer ID'
      });
    }

    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;

    const [totalEarnings, stats] = await Promise.all([
      Consultation.getTotalEarnings(astrologerId, start, end),
      Consultation.getConsultationStats(astrologerId)
    ]);

    res.status(200).json({
      success: true,
      data: {
        totalEarnings: totalEarnings[0]?.totalEarnings || 0,
        stats: stats
      }
    });

  } catch (error) {
    console.error('Error fetching consultation stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch consultation statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Add notes to consultation
const addConsultationNotes = async (req, res) => {
  try {
    const { consultationId } = req.params;
    const { notes } = req.body;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    if (!notes || notes.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Notes are required'
      });
    }

    const consultation = await Consultation.findByIdAndUpdate(
      consultationId,
      { notes: notes.trim() },
      { new: true, runValidators: true }
    ).populate('astrologerId', 'name phone email');

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notes added successfully',
      data: consultation
    });

  } catch (error) {
    console.error('Error adding consultation notes:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add consultation notes',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Add rating and feedback
const addConsultationRating = async (req, res) => {
  try {
    const { consultationId } = req.params;
    const { rating, feedback } = req.body;

    if (!mongoose.Types.ObjectId.isValid(consultationId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation ID'
      });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const consultation = await Consultation.findByIdAndUpdate(
      consultationId,
      { 
        rating: parseInt(rating),
        feedback: feedback ? feedback.trim() : ''
      },
      { new: true, runValidators: true }
    ).populate('astrologerId', 'name phone email');

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Rating added successfully',
      data: consultation
    });

  } catch (error) {
    console.error('Error adding consultation rating:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add consultation rating',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

module.exports = {
  getConsultations,
  getConsultationById,
  createConsultation,
  updateConsultation,
  updateConsultationStatus,
  deleteConsultation,
  getUpcomingConsultations,
  getTodaysConsultations,
  getConsultationStats,
  addConsultationNotes,
  addConsultationRating
};
