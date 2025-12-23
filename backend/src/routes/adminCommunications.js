const express = require('express');
const router = express.Router();
const DirectMessage = require('../models/DirectMessage');
const Call = require('../models/Call');
const Astrologer = require('../models/Astrologer');
const adminAuth = require('../middleware/adminAuth');

/**
 * Helper: Parse period to date range
 */
function getPeriodDates(period = '7d') {
  const endDate = new Date();
  const startDate = new Date();

  switch (period) {
    case '1d':
      startDate.setDate(startDate.getDate() - 1);
      break;
    case '7d':
      startDate.setDate(startDate.getDate() - 7);
      break;
    case '30d':
      startDate.setDate(startDate.getDate() - 30);
      break;
    case '90d':
      startDate.setDate(startDate.getDate() - 90);
      break;
    case '1y':
      startDate.setFullYear(startDate.getFullYear() - 1);
      break;
    default:
      startDate.setDate(startDate.getDate() - 7);
  }

  // Set to start of day
  startDate.setHours(0, 0, 0, 0);
  endDate.setHours(23, 59, 59, 999);

  return { startDate, endDate };
}

/**
 * Helper: Build match filter for communications involving astrologers
 * Includes: admin↔astrologer AND user↔astrologer
 * Excludes: astrologer↔astrologer, admin↔admin
 */
function getAstrologerInvolvedMatch(startDate, endDate) {
  return {
    $or: [
      // Admin to astrologer
      { senderType: 'admin', recipientType: 'astrologer' },
      { recipientType: 'admin', senderType: 'astrologer' },
      // User to astrologer
      { senderType: 'user', recipientType: 'astrologer' },
      { recipientType: 'user', senderType: 'astrologer' },
    ],
    timestamp: { $gte: startDate, $lte: endDate },
    messageType: { $ne: 'call_log' }, // Exclude call log messages
    isDeleted: { $ne: true },
  };
}

function getAstrologerInvolvedCallMatch(startDate, endDate) {
  return {
    $or: [
      // Admin to astrologer
      { callerType: 'admin', recipientType: 'astrologer' },
      { recipientType: 'admin', callerType: 'astrologer' },
      // User to astrologer
      { callerType: 'user', recipientType: 'astrologer' },
      { recipientType: 'user', callerType: 'astrologer' },
    ],
    startedAt: { $gte: startDate, $lte: endDate },
  };
}

/**
 * Helper: Fill missing dates in trends array
 */
function fillMissingDates(trends, startDate, endDate) {
  const filled = [];
  const trendMap = new Map();
  trends.forEach((t) => trendMap.set(t.date, t));

  const current = new Date(startDate);
  while (current <= endDate) {
    const dateStr = current.toISOString().split('T')[0];
    if (trendMap.has(dateStr)) {
      filled.push(trendMap.get(dateStr));
    } else {
      filled.push({
        date: dateStr,
        messages: 0,
        voiceCalls: 0,
        videoCalls: 0,
        total: 0,
      });
    }
    current.setDate(current.getDate() + 1);
  }

  return filled;
}

/**
 * Helper: Fill missing hours (0-23)
 */
function fillMissingHours(peakHours) {
  const filled = [];
  const hourMap = new Map();
  peakHours.forEach((h) => hourMap.set(h.hour, h));

  for (let hour = 0; hour < 24; hour++) {
    if (hourMap.has(hour)) {
      filled.push(hourMap.get(hour));
    } else {
      filled.push({
        hour,
        messages: 0,
        voiceCalls: 0,
        videoCalls: 0,
        total: 0,
      });
    }
  }

  return filled;
}

// ============================================================================
// ADMIN COMMUNICATION ANALYTICS ROUTES
// ============================================================================

/**
 * @route   GET /api/admin/communications/stats
 * @desc    Get overview communication statistics
 * @access  Private (Admin only)
 */
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Stats requested for period: ${period} (${startDate.toISOString()} to ${endDate.toISOString()})`);

    // Build match filters
    const messageMatch = getAstrologerInvolvedMatch(startDate, endDate);
    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Parallel queries for performance
    const [
      totalMessages,
      totalVoiceCalls,
      totalVideoCalls,
      avgCallDurationResult,
      activeConversations,
      completedCalls,
      missedCalls,
      rejectedCalls,
    ] = await Promise.all([
      // Total messages
      DirectMessage.countDocuments(messageMatch),

      // Total voice calls
      Call.countDocuments({
        ...callMatch,
        callType: 'voice',
      }),

      // Total video calls
      Call.countDocuments({
        ...callMatch,
        callType: 'video',
      }),

      // Average call duration (in minutes)
      Call.aggregate([
        {
          $match: {
            ...callMatch,
            duration: { $gt: 0 },
            $or: [
              { status: 'ended' },
              { endReason: 'completed' },
            ],
          },
        },
        {
          $group: {
            _id: null,
            avgDuration: { $avg: '$duration' }, // in seconds
          },
        },
      ]),

      // Active conversations (distinct conversationIds)
      DirectMessage.distinct('conversationId', messageMatch),

      // Completed calls
      Call.countDocuments({
        ...callMatch,
        $or: [
          { status: 'ended' },
          { endReason: 'completed' },
        ],
      }),

      // Missed calls
      Call.countDocuments({
        ...callMatch,
        $or: [
          { status: 'missed' },
          { endReason: { $in: ['missed', 'timeout'] } },
        ],
      }),

      // Rejected calls
      Call.countDocuments({
        ...callMatch,
        $or: [
          { status: 'rejected' },
          { endReason: 'declined' },
        ],
      }),
    ]);

    const totalCommunications = totalMessages + totalVoiceCalls + totalVideoCalls;
    const avgCallDuration = avgCallDurationResult[0]?.avgDuration
      ? Math.round((avgCallDurationResult[0].avgDuration / 60) * 10) / 10 // Convert seconds to minutes, round to 1 decimal
      : 0;

    console.log(`✅ [COMM-ANALYTICS] Stats computed: ${totalMessages} messages, ${totalVoiceCalls} voice, ${totalVideoCalls} video`);

    res.json({
      success: true,
      data: {
        totalMessages,
        totalVoiceCalls,
        totalVideoCalls,
        totalCommunications,
        avgCallDuration,
        activeConversations: activeConversations.length,
        completedCalls,
        missedCalls,
        rejectedCalls,
      },
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch communication statistics',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/communications/trends
 * @desc    Get communication trends over time (daily)
 * @access  Private (Admin only)
 */
router.get('/trends', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Trends requested for period: ${period}`);

    const messageMatch = getAstrologerInvolvedMatch(startDate, endDate);
    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Aggregate messages by date
    const messageTrends = await DirectMessage.aggregate([
      { $match: messageMatch },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$timestamp' },
          },
          messages: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Aggregate calls by date and type
    const callTrends = await Call.aggregate([
      { $match: callMatch },
      {
        $group: {
          _id: {
            date: {
              $dateToString: { format: '%Y-%m-%d', date: '$startedAt' },
            },
            callType: '$callType',
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.date': 1 } },
    ]);

    // Merge message and call data by date
    const trendMap = new Map();

    // Add messages
    messageTrends.forEach((item) => {
      const date = item._id;
      if (!trendMap.has(date)) {
        trendMap.set(date, {
          date,
          messages: 0,
          voiceCalls: 0,
          videoCalls: 0,
          total: 0,
        });
      }
      trendMap.get(date).messages = item.messages;
    });

    // Add calls
    callTrends.forEach((item) => {
      const date = item._id.date;
      if (!trendMap.has(date)) {
        trendMap.set(date, {
          date,
          messages: 0,
          voiceCalls: 0,
          videoCalls: 0,
          total: 0,
        });
      }
      const trend = trendMap.get(date);
      if (item._id.callType === 'voice') {
        trend.voiceCalls = item.count;
      } else if (item._id.callType === 'video') {
        trend.videoCalls = item.count;
      }
    });

    // Calculate totals and convert to array
    const trends = Array.from(trendMap.values()).map((t) => ({
      ...t,
      total: t.messages + t.voiceCalls + t.videoCalls,
    }));

    // Fill missing dates
    const filledTrends = fillMissingDates(trends, startDate, endDate);

    console.log(`✅ [COMM-ANALYTICS] Trends computed: ${filledTrends.length} days`);

    res.json({
      success: true,
      data: filledTrends,
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching trends:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch communication trends',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/communications/astrologers
 * @desc    Get communication volume by astrologer
 * @access  Private (Admin only)
 */
router.get('/astrologers', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Astrologer stats requested for period: ${period}`);

    const messageMatch = getAstrologerInvolvedMatch(startDate, endDate);
    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Aggregate messages by astrologer
    const messageStats = await DirectMessage.aggregate([
      { $match: messageMatch },
      {
        $group: {
          _id: {
            $cond: [
              { $eq: ['$senderType', 'astrologer'] },
              '$senderId',
              '$recipientId',
            ],
          },
          messages: { $sum: 1 },
        },
      },
    ]);

    // Aggregate calls by astrologer and type
    const callStats = await Call.aggregate([
      { $match: callMatch },
      {
        $group: {
          _id: {
            astrologerId: {
              $cond: [
                { $eq: ['$callerType', 'astrologer'] },
                '$callerId',
                '$recipientId',
              ],
            },
            callType: '$callType',
          },
          count: { $sum: 1 },
        },
      },
    ]);

    // Get all unique astrologer IDs
    const astrologerIds = new Set();
    messageStats.forEach((s) => astrologerIds.add(s._id));
    callStats.forEach((s) => astrologerIds.add(s._id.astrologerId));

    // Fetch astrologer names
    const astrologers = await Astrologer.find({
      _id: { $in: Array.from(astrologerIds) },
    }).select('_id name').lean();

    const astrologerMap = new Map();
    astrologers.forEach((a) => {
      astrologerMap.set(a._id.toString(), a.name || 'Unknown');
    });

    // Build result map
    const resultMap = new Map();

    // Add messages
    messageStats.forEach((stat) => {
      const astrologerId = stat._id.toString();
      if (!resultMap.has(astrologerId)) {
        resultMap.set(astrologerId, {
          astrologerId,
          astrologerName: astrologerMap.get(astrologerId) || 'Unknown',
          messages: 0,
          voiceCalls: 0,
          videoCalls: 0,
          total: 0,
        });
      }
      resultMap.get(astrologerId).messages = stat.messages;
    });

    // Add calls
    callStats.forEach((stat) => {
      const astrologerId = stat._id.astrologerId.toString();
      if (!resultMap.has(astrologerId)) {
        resultMap.set(astrologerId, {
          astrologerId,
          astrologerName: astrologerMap.get(astrologerId) || 'Unknown',
          messages: 0,
          voiceCalls: 0,
          videoCalls: 0,
          total: 0,
        });
      }
      const result = resultMap.get(astrologerId);
      if (stat._id.callType === 'voice') {
        result.voiceCalls = stat.count;
      } else if (stat._id.callType === 'video') {
        result.videoCalls = stat.count;
      }
    });

    // Calculate totals and sort
    const astrologerStats = Array.from(resultMap.values())
      .map((stat) => ({
        ...stat,
        total: stat.messages + stat.voiceCalls + stat.videoCalls,
      }))
      .sort((a, b) => b.total - a.total);

    console.log(`✅ [COMM-ANALYTICS] Astrologer stats computed: ${astrologerStats.length} astrologers`);

    res.json({
      success: true,
      data: astrologerStats,
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching astrologer stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch astrologer communication statistics',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/communications/call-duration
 * @desc    Get average call duration per astrologer
 * @access  Private (Admin only)
 */
router.get('/call-duration', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Call duration stats requested for period: ${period}`);

    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Aggregate call duration by astrologer and call type
    const durationStats = await Call.aggregate([
      {
        $match: {
          ...callMatch,
          duration: { $gt: 0 }, // Only calls with duration
        },
      },
      {
        $group: {
          _id: {
            astrologerId: {
              $cond: [
                { $eq: ['$callerType', 'astrologer'] },
                '$callerId',
                '$recipientId',
              ],
            },
            callType: '$callType',
          },
          avgDuration: { $avg: '$duration' }, // in seconds
          count: { $sum: 1 },
        },
      },
    ]);

    // Get unique astrologer IDs
    const astrologerIds = new Set();
    durationStats.forEach((s) => astrologerIds.add(s._id.astrologerId));

    // Fetch astrologer names
    const astrologers = await Astrologer.find({
      _id: { $in: Array.from(astrologerIds) },
    }).select('_id name').lean();

    const astrologerMap = new Map();
    astrologers.forEach((a) => {
      astrologerMap.set(a._id.toString(), a.name || 'Unknown');
    });

    // Build result map
    const resultMap = new Map();

    durationStats.forEach((stat) => {
      const astrologerId = stat._id.astrologerId.toString();
      if (!resultMap.has(astrologerId)) {
        resultMap.set(astrologerId, {
          astrologerId,
          astrologerName: astrologerMap.get(astrologerId) || 'Unknown',
          avgVoiceCallDuration: 0,
          avgVideoCallDuration: 0,
          totalVoiceCalls: 0,
          totalVideoCalls: 0,
        });
      }
      const result = resultMap.get(astrologerId);
      const durationMinutes = Math.round((stat.avgDuration / 60) * 10) / 10; // Convert to minutes, round to 1 decimal

      if (stat._id.callType === 'voice') {
        result.avgVoiceCallDuration = durationMinutes;
        result.totalVoiceCalls = stat.count;
      } else if (stat._id.callType === 'video') {
        result.avgVideoCallDuration = durationMinutes;
        result.totalVideoCalls = stat.count;
      }
    });

    const callDurationStats = Array.from(resultMap.values());

    console.log(`✅ [COMM-ANALYTICS] Call duration stats computed: ${callDurationStats.length} astrologers`);

    res.json({
      success: true,
      data: callDurationStats,
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching call duration stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch call duration statistics',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/communications/peak-hours
 * @desc    Get hourly communication volume (0-23)
 * @access  Private (Admin only)
 */
router.get('/peak-hours', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Peak hours requested for period: ${period}`);

    const messageMatch = getAstrologerInvolvedMatch(startDate, endDate);
    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Aggregate messages by hour
    const messageHours = await DirectMessage.aggregate([
      { $match: messageMatch },
      {
        $group: {
          _id: { $hour: '$timestamp' },
          messages: { $sum: 1 },
        },
      },
    ]);

    // Aggregate calls by hour and type
    const callHours = await Call.aggregate([
      { $match: callMatch },
      {
        $group: {
          _id: {
            hour: { $hour: '$startedAt' },
            callType: '$callType',
          },
          count: { $sum: 1 },
        },
      },
    ]);

    // Build result map
    const hourMap = new Map();

    // Initialize all hours 0-23
    for (let hour = 0; hour < 24; hour++) {
      hourMap.set(hour, {
        hour,
        messages: 0,
        voiceCalls: 0,
        videoCalls: 0,
        total: 0,
      });
    }

    // Add messages
    messageHours.forEach((item) => {
      const hour = item._id;
      if (hourMap.has(hour)) {
        hourMap.get(hour).messages = item.messages;
      }
    });

    // Add calls
    callHours.forEach((item) => {
      const hour = item._id.hour;
      if (hourMap.has(hour)) {
        const hourData = hourMap.get(hour);
        if (item._id.callType === 'voice') {
          hourData.voiceCalls = item.count;
        } else if (item._id.callType === 'video') {
          hourData.videoCalls = item.count;
        }
      }
    });

    // Calculate totals
    const peakHours = Array.from(hourMap.values())
      .map((h) => ({
        ...h,
        total: h.messages + h.voiceCalls + h.videoCalls,
      }))
      .sort((a, b) => a.hour - b.hour);

    console.log(`✅ [COMM-ANALYTICS] Peak hours computed: 24 hours`);

    res.json({
      success: true,
      data: peakHours,
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching peak hours:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch peak hours data',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/communications/success-rates
 * @desc    Get call success rate trends (daily)
 * @access  Private (Admin only)
 */
router.get('/success-rates', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const { startDate, endDate } = getPeriodDates(period);

    console.log(`📊 [COMM-ANALYTICS] Success rates requested for period: ${period}`);

    const callMatch = getAstrologerInvolvedCallMatch(startDate, endDate);

    // Aggregate calls by date and status/endReason
    const callStats = await Call.aggregate([
      { $match: callMatch },
      {
        $group: {
          _id: {
            date: {
              $dateToString: { format: '%Y-%m-%d', date: '$startedAt' },
            },
            status: {
              $cond: [
                {
                  $or: [
                    { $eq: ['$status', 'ended'] },
                    { $eq: ['$endReason', 'completed'] },
                  ],
                },
                'completed',
                {
                  $cond: [
                    {
                      $or: [
                        { $eq: ['$status', 'missed'] },
                        { $in: ['$endReason', ['missed', 'timeout']] },
                      ],
                    },
                    'missed',
                    {
                      $cond: [
                        {
                          $or: [
                            { $eq: ['$status', 'rejected'] },
                            { $eq: ['$endReason', 'declined'] },
                          ],
                        },
                        'rejected',
                        'other',
                      ],
                    },
                  ],
                },
              ],
            },
          },
          count: { $sum: 1 },
        },
      },
    ]);

    // Group by date
    const dateMap = new Map();

    callStats.forEach((stat) => {
      const date = stat._id.date;
      if (!dateMap.has(date)) {
        dateMap.set(date, {
          date,
          completed: 0,
          missed: 0,
          rejected: 0,
          total: 0,
        });
      }
      const dayData = dateMap.get(date);
      if (stat._id.status === 'completed') {
        dayData.completed = stat.count;
      } else if (stat._id.status === 'missed') {
        dayData.missed = stat.count;
      } else if (stat._id.status === 'rejected') {
        dayData.rejected = stat.count;
      }
      dayData.total = dayData.completed + dayData.missed + dayData.rejected;
    });

    // Calculate rates and fill missing dates
    const successRates = fillMissingDates(
      Array.from(dateMap.values()).map((day) => ({
        date: day.date,
        completedRate: day.total > 0 ? Math.round((day.completed / day.total) * 100 * 10) / 10 : 0,
        missedRate: day.total > 0 ? Math.round((day.missed / day.total) * 100 * 10) / 10 : 0,
        rejectedRate: day.total > 0 ? Math.round((day.rejected / day.total) * 100 * 10) / 10 : 0,
      })),
      startDate,
      endDate
    );

    console.log(`✅ [COMM-ANALYTICS] Success rates computed: ${successRates.length} days`);

    res.json({
      success: true,
      data: successRates,
    });
  } catch (error) {
    console.error('❌ [COMM-ANALYTICS] Error fetching success rates:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch call success rate trends',
      error: error.message,
    });
  }
});

module.exports = router;

