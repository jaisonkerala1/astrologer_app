const Astrologer = require('../models/Astrologer');

// Get response time statistics
const getResponseTimeStats = async (req, res) => {
  try {
    const { astrologerId } = req.user;

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    const stats = astrologer.getResponseTimeStats();

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get response time stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get response time statistics'
    });
  }
};

// Update response time for a consultation
const updateResponseTime = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { consultationId, responseTime, consultationType } = req.body;

    // Validate input
    if (!consultationId || !responseTime || !consultationType) {
      return res.status(400).json({
        success: false,
        message: 'consultationId, responseTime, and consultationType are required'
      });
    }

    if (responseTime < 0) {
      return res.status(400).json({
        success: false,
        message: 'Response time must be a positive number'
      });
    }

    const validTypes = ['call', 'video', 'chat', 'in_person'];
    if (!validTypes.includes(consultationType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid consultation type. Must be one of: ' + validTypes.join(', ')
      });
    }

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Check if consultation already has response time recorded
    const existingEntry = astrologer.responseTimeStats.responseTimeHistory.find(
      entry => entry.consultationId === consultationId
    );

    if (existingEntry) {
      return res.status(400).json({
        success: false,
        message: 'Response time for this consultation has already been recorded'
      });
    }

    // Update response time
    await astrologer.updateResponseTime(consultationId, responseTime, consultationType);

    console.log(`Response time updated for astrologer ${astrologerId}, consultation ${consultationId}: ${responseTime} minutes`);

    res.json({
      success: true,
      message: 'Response time updated successfully',
      data: {
        consultationId,
        responseTime,
        consultationType,
        averageResponseTime: astrologer.responseTimeStats.averageResponseTime
      }
    });
  } catch (error) {
    console.error('Update response time error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update response time'
    });
  }
};

// Get response time history with pagination
const getResponseTimeHistory = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { page = 1, limit = 20, consultationType } = req.query;

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    let history = astrologer.responseTimeStats.responseTimeHistory;

    // Filter by consultation type if provided
    if (consultationType) {
      history = history.filter(entry => entry.consultationType === consultationType);
    }

    // Sort by timestamp (newest first)
    history.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Pagination
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const paginatedHistory = history.slice(startIndex, endIndex);

    res.json({
      success: true,
      data: {
        history: paginatedHistory,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(history.length / limit),
          totalItems: history.length,
          itemsPerPage: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Get response time history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get response time history'
    });
  }
};

// Get response time analytics (trends, insights)
const getResponseTimeAnalytics = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const { period = '30' } = req.query; // days

    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(period));

    const recentHistory = astrologer.responseTimeStats.responseTimeHistory.filter(
      entry => new Date(entry.timestamp) >= cutoffDate
    );

    // Calculate trends
    const responseTimes = recentHistory.map(entry => entry.responseTime);
    const avgResponseTime = responseTimes.length > 0 
      ? responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length 
      : 0;

    // Group by day for trend analysis
    const dailyStats = {};
    recentHistory.forEach(entry => {
      const date = new Date(entry.timestamp).toISOString().split('T')[0];
      if (!dailyStats[date]) {
        dailyStats[date] = { count: 0, totalTime: 0, avgTime: 0 };
      }
      dailyStats[date].count += 1;
      dailyStats[date].totalTime += entry.responseTime;
      dailyStats[date].avgTime = dailyStats[date].totalTime / dailyStats[date].count;
    });

    // Calculate improvement trend
    const sortedHistory = recentHistory.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
    const firstHalf = sortedHistory.slice(0, Math.floor(sortedHistory.length / 2));
    const secondHalf = sortedHistory.slice(Math.floor(sortedHistory.length / 2));

    const firstHalfAvg = firstHalf.length > 0 
      ? firstHalf.reduce((sum, entry) => sum + entry.responseTime, 0) / firstHalf.length 
      : 0;
    const secondHalfAvg = secondHalf.length > 0 
      ? secondHalf.reduce((sum, entry) => sum + entry.responseTime, 0) / secondHalf.length 
      : 0;

    const improvement = firstHalfAvg > 0 ? ((firstHalfAvg - secondHalfAvg) / firstHalfAvg) * 100 : 0;

    res.json({
      success: true,
      data: {
        period: `${period} days`,
        averageResponseTime: avgResponseTime,
        totalResponses: recentHistory.length,
        dailyTrends: Object.entries(dailyStats).map(([date, stats]) => ({
          date,
          ...stats
        })),
        improvement: {
          percentage: improvement,
          trend: improvement > 0 ? 'improving' : improvement < 0 ? 'declining' : 'stable',
          firstHalfAvg,
          secondHalfAvg
        },
        byConsultationType: astrologer.getResponseTimeStats().byConsultationType
      }
    });
  } catch (error) {
    console.error('Get response time analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get response time analytics'
    });
  }
};

module.exports = {
  getResponseTimeStats,
  updateResponseTime,
  getResponseTimeHistory,
  getResponseTimeAnalytics
};
