const Astrologer = require('../models/Astrologer');
const Consultation = require('../models/Consultation');

// Get dashboard stats
const getDashboardStats = async (req, res) => {
  try {
    const { astrologerId } = req.user;

    // Get astrologer info
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get today's consultations
    const todaysConsultations = await Consultation.find({
      astrologerId,
      scheduledTime: { $gte: today, $lt: tomorrow },
      status: 'completed'
    });

    // Calculate today's earnings
    const todayEarnings = todaysConsultations.reduce((sum, consultation) => sum + (consultation.amount || 0), 0);

    // Get total consultations count
    const totalConsultations = await Consultation.countDocuments({
      astrologerId,
      status: 'completed'
    });

    // Calculate average consultation duration
    const avgDuration = todaysConsultations.length > 0 
      ? todaysConsultations.reduce((sum, consultation) => sum + (consultation.duration || 0), 0) / todaysConsultations.length
      : 0;

    // Calculate average rating
    const consultationsWithRating = await Consultation.find({
      astrologerId,
      status: 'completed',
      astrologerRating: { $exists: true, $ne: null }
    });

    const avgRating = consultationsWithRating.length > 0
      ? consultationsWithRating.reduce((sum, consultation) => sum + (consultation.astrologerRating || 0), 0) / consultationsWithRating.length
      : 0;

    res.json({
      success: true,
      data: {
        todayEarnings,
        totalEarnings: astrologer.totalEarnings || 0,
        callsToday: todaysConsultations.length,
        totalCalls: totalConsultations,
        isOnline: astrologer.isOnline,
        totalSessions: totalConsultations,
        averageSessionDuration: avgDuration,
        averageRating: avgRating
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get dashboard stats'
    });
  }
};

// Update online status
const updateOnlineStatus = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { isOnline } = req.body;

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    astrologer.isOnline = isOnline;
    astrologer.lastSeen = new Date();
    await astrologer.save();

    res.json({
      success: true,
      message: `Status updated to ${isOnline ? 'online' : 'offline'}`,
      data: {
        isOnline: astrologer.isOnline,
        lastSeen: astrologer.lastSeen
      }
    });
  } catch (error) {
    console.error('Update online status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update online status'
    });
  }
};

// Get recent consultations
const getRecentSessions = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { limit = 10, page = 1 } = req.query;

    const consultations = await Consultation.find({
      astrologerId,
      status: 'completed'
    })
    .sort({ scheduledTime: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit)
    .select('clientName clientPhone duration amount scheduledTime type astrologerRating');

    const totalConsultations = await Consultation.countDocuments({
      astrologerId,
      status: 'completed'
    });

    res.json({
      success: true,
      data: {
        sessions: consultations, // Keep same field name for frontend compatibility
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalConsultations / limit),
          totalSessions: totalConsultations,
          hasNext: page * limit < totalConsultations,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get recent consultations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recent consultations'
    });
  }
};

module.exports = {
  getDashboardStats,
  updateOnlineStatus,
  getRecentSessions
};









