const Astrologer = require('../models/Astrologer');
const Session = require('../models/Session');

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

    // Get today's sessions
    const todaysSessions = await Session.find({
      astrologerId,
      startTime: { $gte: today, $lt: tomorrow },
      status: 'completed'
    });

    // Calculate today's earnings
    const todayEarnings = todaysSessions.reduce((sum, session) => sum + session.earnings, 0);

    // Get total sessions count
    const totalSessions = await Session.countDocuments({
      astrologerId,
      status: 'completed'
    });

    // Calculate average session duration
    const avgDuration = todaysSessions.length > 0 
      ? todaysSessions.reduce((sum, session) => sum + session.duration, 0) / todaysSessions.length
      : 0;

    // Calculate average rating
    const sessionsWithRating = await Session.find({
      astrologerId,
      status: 'completed',
      rating: { $exists: true, $ne: null }
    });

    const avgRating = sessionsWithRating.length > 0
      ? sessionsWithRating.reduce((sum, session) => sum + session.rating, 0) / sessionsWithRating.length
      : 0;

    res.json({
      success: true,
      data: {
        todayEarnings,
        totalEarnings: astrologer.totalEarnings,
        callsToday: todaysSessions.length,
        totalCalls: totalSessions,
        isOnline: astrologer.isOnline,
        totalSessions,
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

// Get recent sessions
const getRecentSessions = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { limit = 10, page = 1 } = req.query;

    const sessions = await Session.find({
      astrologerId,
      status: 'completed'
    })
    .sort({ startTime: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit)
    .select('clientName clientPhone duration earnings startTime type rating');

    const totalSessions = await Session.countDocuments({
      astrologerId,
      status: 'completed'
    });

    res.json({
      success: true,
      data: {
        sessions,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalSessions / limit),
          totalSessions,
          hasNext: page * limit < totalSessions,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get recent sessions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recent sessions'
    });
  }
};

module.exports = {
  getDashboardStats,
  updateOnlineStatus,
  getRecentSessions
};









