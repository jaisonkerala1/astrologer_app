const express = require('express');
const router = express.Router();
const adminAuth = require('../middleware/adminAuth');
const ApprovalRequest = require('../models/ApprovalRequest');
const Astrologer = require('../models/Astrologer');
const Service = require('../models/Service');
const Review = require('../models/Review');
const Consultation = require('../models/Consultation');

// Apply admin auth middleware to all routes
router.use(adminAuth);

/**
 * Get All Approval Requests
 * GET /api/admin/approvals
 * Query params: type, status, page, limit, search
 */
router.get('/', async (req, res) => {
  try {
    const {
      type = '',
      status = '',
      page = 1,
      limit = 20,
      search = ''
    } = req.query;

    const query = {};

    // Filter by request type
    if (type && type !== 'all') {
      query.requestType = type;
    }

    // Filter by status
    if (status && status !== 'all') {
      query.status = status;
    }

    // Search by astrologer name, email, or phone
    if (search) {
      query.$or = [
        { astrologerName: { $regex: search, $options: 'i' } },
        { astrologerEmail: { $regex: search, $options: 'i' } },
        { astrologerPhone: { $regex: search, $options: 'i' } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { submittedAt: -1 };

    const [requests, total] = await Promise.all([
      ApprovalRequest.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .populate('astrologerId', 'name email profilePicture specializations experience')
        .populate('serviceId', 'name price category description'),
      ApprovalRequest.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: requests,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get approval requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch approval requests',
      error: error.message
    });
  }
});

/**
 * Get Approval Request Statistics
 * GET /api/admin/approvals/stats
 */
router.get('/stats', async (req, res) => {
  try {
    const [
      totalPending,
      totalApproved,
      totalRejected,
      pendingVerification,
      pendingServices,
      todayReviewed,
      reviewTimeData
    ] = await Promise.all([
      ApprovalRequest.countDocuments({ status: 'pending' }),
      ApprovalRequest.countDocuments({ status: 'approved' }),
      ApprovalRequest.countDocuments({ status: 'rejected' }),
      ApprovalRequest.countDocuments({
        status: 'pending',
        requestType: 'verification_badge'
      }),
      ApprovalRequest.countDocuments({
        status: 'pending',
        requestType: 'service_approval'
      }),
      ApprovalRequest.countDocuments({
        status: { $in: ['approved', 'rejected'] },
        reviewedAt: {
          $gte: new Date(new Date().setHours(0, 0, 0, 0))
        }
      }),
      ApprovalRequest.aggregate([
        {
          $match: {
            status: { $in: ['approved', 'rejected'] },
            reviewedAt: { $ne: null },
            submittedAt: { $ne: null }
          }
        },
        {
          $project: {
            reviewTimeHours: {
              $divide: [
                { $subtract: ['$reviewedAt', '$submittedAt'] },
                1000 * 60 * 60 // Convert milliseconds to hours
              ]
            }
          }
        },
        {
          $group: {
            _id: null,
            avgReviewTime: { $avg: '$reviewTimeHours' }
          }
        }
      ])
    ]);

    const avgReviewTime = reviewTimeData[0]?.avgReviewTime || 0;

    res.json({
      success: true,
      data: {
        totalPending,
        totalApproved,
        totalRejected,
        pendingOnboarding: 0, // Not implemented in this phase
        pendingVerification,
        pendingServices,
        avgReviewTime: Math.round(avgReviewTime * 10) / 10, // Round to 1 decimal
        todayReviewed
      }
    });
  } catch (error) {
    console.error('Get approval stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch approval statistics',
      error: error.message
    });
  }
});

/**
 * Get Single Approval Request
 * GET /api/admin/approvals/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const request = await ApprovalRequest.findById(req.params.id)
      .populate('astrologerId', 'name email phone profilePicture specializations experience bio awards certificates')
      .populate('serviceId', 'name price category description imageUrl');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Approval request not found'
      });
    }

    // Get additional astrologer stats
    const [consultationsCount, reviewStats] = await Promise.all([
      Consultation.countDocuments({ astrologerId: request.astrologerId }),
      Review.aggregate([
        { $match: { astrologerId: request.astrologerId } },
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

    // Enhance request with current astrologer data
    const requestObj = request.toObject();
    requestObj.astrologerData = {
      ...requestObj.astrologerData,
      consultationsCount,
      rating: Math.round((ratingData.avgRating || 0) * 10) / 10
    };

    res.json({
      success: true,
      data: requestObj
    });
  } catch (error) {
    console.error('Get approval request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch approval request',
      error: error.message
    });
  }
});

/**
 * Approve Request
 * POST /api/admin/approvals/:id/approve
 * Body: { notes?: string }
 */
router.post('/:id/approve', async (req, res) => {
  try {
    const { notes } = req.body;
    const request = await ApprovalRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Approval request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Request is already ${request.status}`
      });
    }

    // Approve the request
    await request.approve('admin', notes);

    // Update related models based on request type
    if (request.requestType === 'verification_badge') {
      // Update astrologer verification status
      await Astrologer.findByIdAndUpdate(request.astrologerId, {
        $set: {
          isVerified: true,
          verificationStatus: 'approved',
          verificationApprovedAt: new Date()
        }
      });
    } else if (request.requestType === 'service_approval') {
      // Activate the service
      if (request.serviceId) {
        await Service.findByIdAndUpdate(request.serviceId, {
          $set: {
            isActive: true
          }
        });
      }
    }

    // Fetch updated request with populated fields
    const updatedRequest = await ApprovalRequest.findById(req.params.id)
      .populate('astrologerId', 'name email profilePicture')
      .populate('serviceId', 'name price category');

    res.json({
      success: true,
      data: updatedRequest,
      message: 'Request approved successfully'
    });
  } catch (error) {
    console.error('Approve request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve request',
      error: error.message
    });
  }
});

/**
 * Reject Request
 * POST /api/admin/approvals/:id/reject
 * Body: { reason: string }
 */
router.post('/:id/reject', async (req, res) => {
  try {
    const { reason } = req.body;

    if (!reason || reason.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required'
      });
    }

    const request = await ApprovalRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Approval request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Request is already ${request.status}`
      });
    }

    // Reject the request
    await request.reject('admin', reason);

    // Update related models based on request type
    if (request.requestType === 'verification_badge') {
      // Update astrologer verification status
      await Astrologer.findByIdAndUpdate(request.astrologerId, {
        $set: {
          verificationStatus: 'rejected',
          verificationRejectionReason: reason
        }
      });
    }

    // Fetch updated request with populated fields
    const updatedRequest = await ApprovalRequest.findById(req.params.id)
      .populate('astrologerId', 'name email profilePicture')
      .populate('serviceId', 'name price category');

    res.json({
      success: true,
      data: updatedRequest,
      message: 'Request rejected successfully'
    });
  } catch (error) {
    console.error('Reject request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject request',
      error: error.message
    });
  }
});

module.exports = router;

