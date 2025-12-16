const express = require('express');
const router = express.Router();
const adminAuth = require('../middleware/adminAuth');
const Astrologer = require('../models/Astrologer');
const User = require('../models/User');
const Consultation = require('../models/Consultation');
const Service = require('../models/Service');
const ServiceRequest = require('../models/ServiceRequest');
const Review = require('../models/Review');
const LiveStream = require('../models/LiveStream');
const Discussion = require('../models/Discussion');
const DiscussionComment = require('../models/DiscussionComment');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// ============================================
// ADMIN AUTHENTICATION
// ============================================

/**
 * Admin Login
 * POST /api/admin/login
 */
router.post('/login', (req, res) => {
  try {
    const { adminKey } = req.body;
    
    if (!adminKey) {
      return res.status(400).json({
        success: false,
        message: 'Admin key is required'
      });
    }
    
    const validAdminKey = process.env.ADMIN_SECRET_KEY;
    
    if (adminKey !== validAdminKey) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin credentials'
      });
    }
    
    res.json({
      success: true,
      data: {
        authenticated: true,
        adminKey: adminKey,
        loginAt: new Date()
      },
      message: 'Admin logged in successfully'
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message
    });
  }
});

// Apply admin auth middleware to all routes below
router.use(adminAuth);

// ============================================
// DASHBOARD STATISTICS
// ============================================

/**
 * Get Platform Dashboard Stats
 * GET /api/admin/dashboard/stats
 */
router.get('/dashboard/stats', async (req, res) => {
  try {
    // Get current month date range
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const [
      totalAstrologers,
      activeAstrologers,
      pendingApprovals,
      suspendedAstrologers,
      onlineAstrologers,
      totalUsers,
      activeUsers,
      bannedUsers,
      totalConsultations,
      completedConsultations,
      ongoingConsultations,
      totalRevenue,
      monthlyRevenue,
      activeStreams,
      totalReviews,
      totalServices,
      activeServices,
      pendingServices,
      totalDiscussions
    ] = await Promise.all([
      Astrologer.countDocuments(),
      Astrologer.countDocuments({ isActive: true, isApproved: true, isSuspended: false }),
      Astrologer.countDocuments({ isApproved: false, isSuspended: false }),
      Astrologer.countDocuments({ isSuspended: true }),
      Astrologer.countDocuments({ isOnline: true, isApproved: true }),
      User.countDocuments(),
      User.countDocuments({ isActive: true, isBanned: false }),
      User.countDocuments({ isBanned: true }),
      Consultation.countDocuments(),
      Consultation.countDocuments({ status: 'completed' }),
      Consultation.countDocuments({ status: { $in: ['pending', 'ongoing', 'in_progress'] } }),
      Consultation.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Consultation.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: firstDayOfMonth, $lte: lastDayOfMonth } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      LiveStream.countDocuments({ isLive: true }),
      Review.countDocuments(),
      Service.countDocuments({ isDeleted: false }),
      Service.countDocuments({ isActive: true, isDeleted: false }),
      Service.countDocuments({ isActive: false, isDeleted: false }),
      Discussion.countDocuments()
    ]);

    res.json({
      success: true,
      data: {
        astrologers: {
          total: totalAstrologers,
          active: activeAstrologers,
          pendingApprovals: pendingApprovals,
          suspended: suspendedAstrologers,
          online: onlineAstrologers
        },
        users: {
          total: totalUsers,
          active: activeUsers,
          banned: bannedUsers
        },
        consultations: {
          total: totalConsultations,
          completed: completedConsultations,
          ongoing: ongoingConsultations
        },
        revenue: {
          total: totalRevenue[0]?.total || 0,
          monthly: monthlyRevenue[0]?.total || 0
        },
        liveStreams: {
          active: activeStreams
        },
        reviews: {
          total: totalReviews
        },
        services: {
          total: totalServices,
          active: activeServices,
          pending: pendingServices
        },
        discussions: {
          total: totalDiscussions
        }
      }
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard stats',
      error: error.message
    });
  }
});

// ============================================
// ASTROLOGER MANAGEMENT
// ============================================

/**
 * Get All Astrologers
 * GET /api/admin/astrologers
 */
router.get('/astrologers', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = '',
      isApproved = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (status === 'active') query.isActive = true;
    if (status === 'inactive') query.isActive = false;
    if (status === 'suspended') query.isSuspended = true;
    
    if (isApproved === 'true') query.isApproved = true;
    if (isApproved === 'false') query.isApproved = false;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [astrologers, total] = await Promise.all([
      Astrologer.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .select('-activeSession'),
      Astrologer.countDocuments(query)
    ]);

    // Get ratings and review counts for all astrologers
    const astrologerIds = astrologers.map(a => a._id);
    const reviewStats = await Review.aggregate([
      { $match: { astrologerId: { $in: astrologerIds } } },
      { 
        $group: { 
          _id: '$astrologerId', 
          avgRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 }
        } 
      }
    ]);

    // Create a map for quick lookup
    const reviewStatsMap = {};
    reviewStats.forEach(stat => {
      reviewStatsMap[stat._id.toString()] = {
        rating: Math.round(stat.avgRating * 10) / 10, // Round to 1 decimal
        totalReviews: stat.totalReviews
      };
    });

    // Enhance astrologers with rating data and normalize field names
    const enhancedAstrologers = astrologers.map(astrologer => {
      const astroObj = astrologer.toObject();
      const stats = reviewStatsMap[astrologer._id.toString()] || { rating: 0, totalReviews: 0 };
      
      return {
        ...astroObj,
        // Map specializations to specialization for frontend compatibility
        specialization: astroObj.specializations || [],
        // Add rating and review stats
        rating: stats.rating,
        totalReviews: stats.totalReviews,
        // Map ratePerMinute to consultationCharge for frontend
        consultationCharge: astroObj.ratePerMinute || 0,
        callCharge: astroObj.ratePerMinute || 0,
        chatCharge: astroObj.ratePerMinute || 0,
      };
    });

    res.json({
      success: true,
      data: enhancedAstrologers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get astrologers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch astrologers',
      error: error.message
    });
  }
});

/**
 * Get Single Astrologer
 * GET /api/admin/astrologers/:id
 */
router.get('/astrologers/:id', async (req, res) => {
  try {
    const astrologer = await Astrologer.findById(req.params.id);
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Get additional stats including rating
    const [consultationsCount, totalEarnings, servicesCount, reviewStats] = await Promise.all([
      Consultation.countDocuments({ astrologerId: astrologer._id }),
      Consultation.aggregate([
        { $match: { astrologerId: astrologer._id, status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Service.countDocuments({ astrologerId: astrologer._id, isDeleted: false }),
      Review.aggregate([
        { $match: { astrologerId: astrologer._id } },
        { 
          $group: { 
            _id: null, 
            avgRating: { $avg: '$rating' },
            totalReviews: { $sum: 1 }
          } 
        }
      ])
    ]);

    const astroObj = astrologer.toObject();
    const ratingData = reviewStats[0] || { avgRating: 0, totalReviews: 0 };

    res.json({
      success: true,
      data: {
        ...astroObj,
        // Map fields for frontend compatibility
        specialization: astroObj.specializations || [],
        rating: Math.round((ratingData.avgRating || 0) * 10) / 10,
        totalReviews: ratingData.totalReviews || 0,
        consultationCharge: astroObj.ratePerMinute || 0,
        callCharge: astroObj.ratePerMinute || 0,
        chatCharge: astroObj.ratePerMinute || 0,
        totalConsultations: consultationsCount,
        stats: {
          consultations: consultationsCount,
          earnings: totalEarnings[0]?.total || astroObj.totalEarnings || 0,
          services: servicesCount,
          reviews: ratingData.totalReviews || 0,
          rating: Math.round((ratingData.avgRating || 0) * 10) / 10
        }
      }
    });
  } catch (error) {
    console.error('Get astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch astrologer',
      error: error.message
    });
  }
});

/**
 * Update Astrologer
 * PUT /api/admin/astrologers/:id
 */
router.put('/astrologers/:id', async (req, res) => {
  try {
    const updates = req.body;
    const astrologer = await Astrologer.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      data: astrologer,
      message: 'Astrologer updated successfully'
    });
  } catch (error) {
    console.error('Update astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update astrologer',
      error: error.message
    });
  }
});

/**
 * Approve Astrologer
 * PATCH /api/admin/astrologers/:id/approve
 */
router.patch('/astrologers/:id/approve', async (req, res) => {
  try {
    const astrologer = await Astrologer.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isApproved: true,
          approvedAt: new Date(),
          approvedBy: 'admin'
        }
      },
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
      data: astrologer,
      message: 'Astrologer approved successfully'
    });
  } catch (error) {
    console.error('Approve astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve astrologer',
      error: error.message
    });
  }
});

/**
 * Suspend Astrologer
 * PATCH /api/admin/astrologers/:id/suspend
 */
router.patch('/astrologers/:id/suspend', async (req, res) => {
  try {
    const { reason } = req.body;
    const astrologer = await Astrologer.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isSuspended: true,
          suspendedAt: new Date(),
          suspensionReason: reason || 'No reason provided',
          isActive: false,
          isOnline: false
        }
      },
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
      data: astrologer,
      message: 'Astrologer suspended successfully'
    });
  } catch (error) {
    console.error('Suspend astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to suspend astrologer',
      error: error.message
    });
  }
});

/**
 * Unsuspend Astrologer
 * PATCH /api/admin/astrologers/:id/unsuspend
 */
router.patch('/astrologers/:id/unsuspend', async (req, res) => {
  try {
    const astrologer = await Astrologer.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isSuspended: false,
          suspendedAt: null,
          suspensionReason: null,
          isActive: true
        }
      },
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
      data: astrologer,
      message: 'Astrologer unsuspended successfully'
    });
  } catch (error) {
    console.error('Unsuspend astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to unsuspend astrologer',
      error: error.message
    });
  }
});

/**
 * Delete Astrologer
 * DELETE /api/admin/astrologers/:id
 */
router.delete('/astrologers/:id', async (req, res) => {
  try {
    const astrologer = await Astrologer.findByIdAndDelete(req.params.id);

    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    res.json({
      success: true,
      message: 'Astrologer deleted successfully'
    });
  } catch (error) {
    console.error('Delete astrologer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete astrologer',
      error: error.message
    });
  }
});

// ============================================
// USER MANAGEMENT
// ============================================

/**
 * Get All Users
 * GET /api/admin/users
 */
router.get('/users', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (status === 'active') {
      query.isActive = true;
      query.isBanned = false;
    }
    if (status === 'banned') query.isBanned = true;
    if (status === 'inactive') query.isActive = false;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [users, total] = await Promise.all([
      User.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
});

/**
 * Get Single User
 * GET /api/admin/users/:id
 */
router.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get user's consultation history
    const consultations = await Consultation.find({ clientEmail: user.email })
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('astrologerId', 'name profilePicture');

    res.json({
      success: true,
      data: {
        ...user.toObject(),
        consultations
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user',
      error: error.message
    });
  }
});

/**
 * Update User
 * PUT /api/admin/users/:id
 */
router.put('/users/:id', async (req, res) => {
  try {
    const updates = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user,
      message: 'User updated successfully'
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
});

/**
 * Ban User
 * PATCH /api/admin/users/:id/ban
 */
router.patch('/users/:id/ban', async (req, res) => {
  try {
    const { reason } = req.body;
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    await user.ban(reason || 'No reason provided');

    res.json({
      success: true,
      data: user,
      message: 'User banned successfully'
    });
  } catch (error) {
    console.error('Ban user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to ban user',
      error: error.message
    });
  }
});

/**
 * Unban User
 * PATCH /api/admin/users/:id/unban
 */
router.patch('/users/:id/unban', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    await user.unban();

    res.json({
      success: true,
      data: user,
      message: 'User unbanned successfully'
    });
  } catch (error) {
    console.error('Unban user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to unban user',
      error: error.message
    });
  }
});

/**
 * Delete User
 * DELETE /api/admin/users/:id
 */
router.delete('/users/:id', async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
});

// ============================================
// CONSULTATION MANAGEMENT
// ============================================

/**
 * Get All Consultations
 * GET /api/admin/consultations
 */
router.get('/consultations', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status = '',
      astrologerId = '',
      fromDate = '',
      toDate = '',
      sortBy = 'scheduledTime',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (status) query.status = status;
    if (astrologerId) query.astrologerId = astrologerId;
    if (fromDate || toDate) {
      query.scheduledTime = {};
      if (fromDate) query.scheduledTime.$gte = new Date(fromDate);
      if (toDate) query.scheduledTime.$lte = new Date(toDate);
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [consultations, total] = await Promise.all([
      Consultation.find(query)
        .populate('astrologerId', 'name email profilePicture')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      Consultation.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: consultations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get consultations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch consultations',
      error: error.message
    });
  }
});

/**
 * Get Single Consultation
 * GET /api/admin/consultations/:id
 */
router.get('/consultations/:id', async (req, res) => {
  try {
    const consultation = await Consultation.findById(req.params.id)
      .populate('astrologerId', 'name email phone profilePicture specializations');

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.json({
      success: true,
      data: consultation
    });
  } catch (error) {
    console.error('Get consultation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch consultation',
      error: error.message
    });
  }
});

/**
 * Update Consultation
 * PUT /api/admin/consultations/:id
 */
router.put('/consultations/:id', async (req, res) => {
  try {
    const updates = req.body;
    const consultation = await Consultation.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.json({
      success: true,
      data: consultation,
      message: 'Consultation updated successfully'
    });
  } catch (error) {
    console.error('Update consultation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update consultation',
      error: error.message
    });
  }
});

/**
 * Delete Consultation
 * DELETE /api/admin/consultations/:id
 */
router.delete('/consultations/:id', async (req, res) => {
  try {
    const consultation = await Consultation.findByIdAndDelete(req.params.id);

    if (!consultation) {
      return res.status(404).json({
        success: false,
        message: 'Consultation not found'
      });
    }

    res.json({
      success: true,
      message: 'Consultation deleted successfully'
    });
  } catch (error) {
    console.error('Delete consultation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete consultation',
      error: error.message
    });
  }
});

// ============================================
// SERVICE MANAGEMENT
// ============================================

/**
 * Get All Services
 * GET /api/admin/services
 */
router.get('/services', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '',
      category = '',
      astrologerId = '',
      isActive = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = { isDeleted: false };
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (category) query.category = category;
    if (astrologerId) query.astrologerId = astrologerId;
    if (isActive === 'true') query.isActive = true;
    if (isActive === 'false') query.isActive = false;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [services, total] = await Promise.all([
      Service.find(query)
        .populate('astrologerId', 'name email profilePicture')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      Service.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: services,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch services',
      error: error.message
    });
  }
});

/**
 * Get Single Service
 * GET /api/admin/services/:id
 */
router.get('/services/:id', async (req, res) => {
  try {
    const service = await Service.findById(req.params.id)
      .populate('astrologerId', 'name email phone profilePicture');

    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    res.json({
      success: true,
      data: service
    });
  } catch (error) {
    console.error('Get service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch service',
      error: error.message
    });
  }
});

/**
 * Update Service
 * PUT /api/admin/services/:id
 */
router.put('/services/:id', async (req, res) => {
  try {
    const updates = req.body;
    const service = await Service.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    res.json({
      success: true,
      data: service,
      message: 'Service updated successfully'
    });
  } catch (error) {
    console.error('Update service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update service',
      error: error.message
    });
  }
});

/**
 * Delete Service
 * DELETE /api/admin/services/:id
 */
router.delete('/services/:id', async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    await service.softDelete();

    res.json({
      success: true,
      message: 'Service deleted successfully'
    });
  } catch (error) {
    console.error('Delete service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete service',
      error: error.message
    });
  }
});

// ============================================
// SERVICE REQUEST MANAGEMENT
// ============================================

/**
 * Get All Service Requests
 * GET /api/admin/service-requests
 */
router.get('/service-requests', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status = '',
      astrologerId = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (status) query.status = status;
    if (astrologerId) query.astrologerId = astrologerId;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [requests, total] = await Promise.all([
      ServiceRequest.find(query)
        .populate('astrologerId', 'name email profilePicture')
        .populate('serviceId', 'name price')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      ServiceRequest.countDocuments(query)
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
    console.error('Get service requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch service requests',
      error: error.message
    });
  }
});

/**
 * Get Single Service Request
 * GET /api/admin/service-requests/:id
 */
router.get('/service-requests/:id', async (req, res) => {
  try {
    const request = await ServiceRequest.findById(req.params.id)
      .populate('astrologerId', 'name email phone profilePicture')
      .populate('serviceId', 'name price description');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }

    res.json({
      success: true,
      data: request
    });
  } catch (error) {
    console.error('Get service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch service request',
      error: error.message
    });
  }
});

/**
 * Update Service Request
 * PUT /api/admin/service-requests/:id
 */
router.put('/service-requests/:id', async (req, res) => {
  try {
    const updates = req.body;
    const request = await ServiceRequest.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }

    res.json({
      success: true,
      data: request,
      message: 'Service request updated successfully'
    });
  } catch (error) {
    console.error('Update service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update service request',
      error: error.message
    });
  }
});

// ============================================
// REVIEW MODERATION
// ============================================

/**
 * Get All Reviews
 * GET /api/admin/reviews
 */
router.get('/reviews', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      rating = '',
      astrologerId = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (rating) query.rating = parseInt(rating);
    if (astrologerId) query.astrologerId = astrologerId;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [reviews, total] = await Promise.all([
      Review.find(query)
        .populate('astrologerId', 'name email profilePicture')
        .populate('clientId', 'name email profilePicture')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      Review.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews',
      error: error.message
    });
  }
});

/**
 * Moderate Review (hide/show)
 * PATCH /api/admin/reviews/:id/moderate
 */
router.patch('/reviews/:id/moderate', async (req, res) => {
  try {
    const { isPublic, isModerated } = req.body;
    const review = await Review.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isPublic: isPublic !== undefined ? isPublic : true,
          isModerated: isModerated !== undefined ? isModerated : true,
          moderatedAt: new Date()
        }
      },
      { new: true }
    );

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    res.json({
      success: true,
      data: review,
      message: 'Review moderated successfully'
    });
  } catch (error) {
    console.error('Moderate review error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to moderate review',
      error: error.message
    });
  }
});

/**
 * Delete Review
 * DELETE /api/admin/reviews/:id
 */
router.delete('/reviews/:id', async (req, res) => {
  try {
    const review = await Review.findByIdAndDelete(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    res.json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    console.error('Delete review error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete review',
      error: error.message
    });
  }
});

// ============================================
// LIVE STREAM MONITORING
// ============================================

/**
 * Get All Live Streams
 * GET /api/admin/live-streams
 */
router.get('/live-streams', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      isLive = '',
      astrologerId = '',
      sortBy = 'startedAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};
    
    if (isLive === 'true') query.isLive = true;
    if (isLive === 'false') query.isLive = false;
    if (astrologerId) query.astrologerId = astrologerId;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [streams, total] = await Promise.all([
      LiveStream.find(query)
        .populate('astrologerId', 'name email profilePicture')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      LiveStream.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: streams,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get live streams error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch live streams',
      error: error.message
    });
  }
});

/**
 * Get Agora Token for Live Stream (Admin Viewer)
 * GET /api/admin/live-streams/:id/token
 */
router.get('/live-streams/:id/token', async (req, res) => {
  try {
    const stream = await LiveStream.findById(req.params.id);

    if (!stream) {
      return res.status(404).json({
        success: false,
        message: 'Live stream not found'
      });
    }

    if (!stream.isLive) {
      return res.status(400).json({
        success: false,
        message: 'Stream is not currently live'
      });
    }

    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;

    if (!appId || !appCertificate) {
      return res.status(500).json({
        success: false,
        message: 'Agora credentials not configured'
      });
    }

    // Generate token using official Agora library
    const uid = 0; // 0 means auto-assign
    const role = RtcRole.SUBSCRIBER; // Admin joins as viewer
    const expirationTimeInSeconds = 86400; // 24 hours
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      stream.agoraChannelName,
      uid,
      role,
      privilegeExpiredTs
    );

    res.json({
      success: true,
      data: {
        token,
        channelName: stream.agoraChannelName,
        appId: appId,
        uid: uid
      }
    });
  } catch (error) {
    console.error('Token generation error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate token'
    });
  }
});

/**
 * Force End Live Stream
 * POST /api/admin/live-streams/:id/end
 */
router.post('/live-streams/:id/end', async (req, res) => {
  try {
    const stream = await LiveStream.findById(req.params.id);

    if (!stream) {
      return res.status(404).json({
        success: false,
        message: 'Live stream not found'
      });
    }

    stream.isLive = false;
    stream.endedAt = new Date();
    await stream.save();

    // Notify via Socket.IO if available
    const io = req.app.get('io');
    if (io) {
      const roomId = `live:${stream._id}`;
      io.to(roomId).emit('live:ended', {
        streamId: stream._id.toString(),
        message: 'Stream ended by admin',
        timestamp: Date.now()
      });
    }

    res.json({
      success: true,
      data: stream,
      message: 'Live stream ended successfully'
    });
  } catch (error) {
    console.error('End live stream error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to end live stream',
      error: error.message
    });
  }
});

// ============================================
// DISCUSSION MODERATION
// ============================================

/**
 * Get All Discussions
 * GET /api/admin/discussions
 */
router.get('/discussions', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      category = '',
      authorId = '',
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = { isDeleted: false };
    
    if (category) query.category = category;
    if (authorId) query.authorId = authorId;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [discussions, total] = await Promise.all([
      Discussion.find(query)
        .populate('authorId', 'name email profilePicture')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      Discussion.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: discussions,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get discussions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch discussions',
      error: error.message
    });
  }
});

/**
 * Delete Discussion
 * DELETE /api/admin/discussions/:id
 */
router.delete('/discussions/:id', async (req, res) => {
  try {
    const discussion = await Discussion.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isDeleted: true,
          deletedAt: new Date()
        }
      },
      { new: true }
    );

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    res.json({
      success: true,
      message: 'Discussion deleted successfully'
    });
  } catch (error) {
    console.error('Delete discussion error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete discussion',
      error: error.message
    });
  }
});

/**
 * Delete Discussion Comment
 * DELETE /api/admin/discussions/comments/:id
 */
router.delete('/discussions/comments/:id', async (req, res) => {
  try {
    const comment = await DiscussionComment.findByIdAndUpdate(
      req.params.id,
      {
        $set: {
          isDeleted: true,
          deletedAt: new Date()
        }
      },
      { new: true }
    );

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    res.json({
      success: true,
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('Delete comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete comment',
      error: error.message
    });
  }
});

// ============================================
// ANALYTICS
// ============================================

/**
 * Get Revenue Analytics
 * GET /api/admin/analytics/revenue
 */
router.get('/analytics/revenue', async (req, res) => {
  try {
    const { period = 'monthly' } = req.query;
    
    let groupBy;
    switch (period) {
      case 'daily':
        groupBy = { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } };
        break;
      case 'weekly':
        groupBy = { $dateToString: { format: '%Y-W%V', date: '$createdAt' } };
        break;
      case 'monthly':
      default:
        groupBy = { $dateToString: { format: '%Y-%m', date: '$createdAt' } };
        break;
    }

    const revenueData = await Consultation.aggregate([
      {
        $match: {
          status: 'completed'
        }
      },
      {
        $group: {
          _id: groupBy,
          revenue: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { _id: 1 }
      },
      {
        $limit: 30
      }
    ]);

    // Get top earning astrologers
    const topEarners = await Consultation.aggregate([
      {
        $match: {
          status: 'completed'
        }
      },
      {
        $group: {
          _id: '$astrologerId',
          earnings: { $sum: '$amount' },
          consultations: { $sum: 1 }
        }
      },
      {
        $sort: { earnings: -1 }
      },
      {
        $limit: 10
      },
      {
        $lookup: {
          from: 'astrologers',
          localField: '_id',
          foreignField: '_id',
          as: 'astrologer'
        }
      },
      {
        $unwind: '$astrologer'
      },
      {
        $project: {
          name: '$astrologer.name',
          email: '$astrologer.email',
          profilePicture: '$astrologer.profilePicture',
          earnings: 1,
          consultations: 1
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        revenueData,
        topEarners
      }
    });
  } catch (error) {
    console.error('Revenue analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch revenue analytics',
      error: error.message
    });
  }
});

/**
 * Get Growth Analytics
 * GET /api/admin/analytics/growth
 */
router.get('/analytics/growth', async (req, res) => {
  try {
    const { period = 'monthly' } = req.query;
    
    let groupBy;
    switch (period) {
      case 'daily':
        groupBy = { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } };
        break;
      case 'weekly':
        groupBy = { $dateToString: { format: '%Y-W%V', date: '$createdAt' } };
        break;
      case 'monthly':
      default:
        groupBy = { $dateToString: { format: '%Y-%m', date: '$createdAt' } };
        break;
    }

    const [userGrowth, astrologerGrowth, consultationGrowth] = await Promise.all([
      User.aggregate([
        {
          $group: {
            _id: groupBy,
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } },
        { $limit: 30 }
      ]),
      Astrologer.aggregate([
        {
          $group: {
            _id: groupBy,
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } },
        { $limit: 30 }
      ]),
      Consultation.aggregate([
        {
          $group: {
            _id: groupBy,
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } },
        { $limit: 30 }
      ])
    ]);

    res.json({
      success: true,
      data: {
        users: userGrowth,
        astrologers: astrologerGrowth,
        consultations: consultationGrowth
      }
    });
  } catch (error) {
    console.error('Growth analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch growth analytics',
      error: error.message
    });
  }
});

/**
 * Get Complete Analytics Dashboard
 * GET /api/admin/analytics
 */
router.get('/analytics', async (req, res) => {
  try {
    const { period = 'monthly' } = req.query;
    
    // Date range helpers
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);
    const lastMonth = new Date(today);
    lastMonth.setMonth(lastMonth.getMonth() - 1);
    const last3Months = new Date(today);
    last3Months.setMonth(last3Months.getMonth() - 3);

    // Group by configuration
    let groupBy;
    switch (period) {
      case 'daily':
        groupBy = { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } };
        break;
      case 'weekly':
        groupBy = { $dateToString: { format: '%Y-W%V', date: '$createdAt' } };
        break;
      case 'monthly':
      default:
        groupBy = { $dateToString: { format: '%Y-%m', date: '$createdAt' } };
        break;
    }

    // ============================================
    // 1. OVERVIEW STATS
    // ============================================
    const [
      totalRevenue,
      todayRevenue,
      yesterdayRevenue,
      weekRevenue,
      monthRevenue,
      totalConsultations,
      todayConsultations,
      completedConsultations,
      totalAstrologers,
      activeAstrologers,
      totalUsers,
      activeUsers,
      totalReviews,
      avgRating,
      totalServices,
      totalLiveStreams,
      activeLiveStreams
    ] = await Promise.all([
      // Revenue stats
      Consultation.aggregate([
        { $match: { status: 'completed', amount: { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]).then(r => r[0]?.total || 0),
      
      Consultation.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: today }, amount: { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]).then(r => r[0]?.total || 0),
      
      Consultation.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: yesterday, $lt: today }, amount: { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]).then(r => r[0]?.total || 0),
      
      Consultation.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: lastWeek }, amount: { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]).then(r => r[0]?.total || 0),
      
      Consultation.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: lastMonth }, amount: { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]).then(r => r[0]?.total || 0),

      // Consultation stats
      Consultation.countDocuments(),
      Consultation.countDocuments({ createdAt: { $gte: today } }),
      Consultation.countDocuments({ status: 'completed' }),

      // User stats
      Astrologer.countDocuments(),
      Astrologer.countDocuments({ approvalStatus: 'approved' }),
      User.countDocuments(),
      User.countDocuments({ status: 'active' }),

      // Review stats
      Review.countDocuments(),
      Review.aggregate([
        { $group: { _id: null, avgRating: { $avg: '$rating' } } }
      ]).then(r => r[0]?.avgRating || 0),

      // Service stats
      Service.countDocuments(),
      
      // Live stream stats
      LiveStream.countDocuments(),
      LiveStream.countDocuments({ isLive: true })
    ]);

    // Calculate growth percentages
    const revenueGrowth = yesterdayRevenue > 0 
      ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100).toFixed(1)
      : 0;

    // ============================================
    // 2. REVENUE TREND
    // ============================================
    const revenueTrend = await Consultation.aggregate([
      {
        $match: {
          status: 'completed',
          amount: { $exists: true },
          createdAt: { $gte: last3Months }
        }
      },
      {
        $group: {
          _id: groupBy,
          revenue: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // ============================================
    // 3. TOP PERFORMING ASTROLOGERS
    // ============================================
    const topAstrologers = await Consultation.aggregate([
      {
        $match: {
          status: 'completed',
          amount: { $exists: true }
        }
      },
      {
        $group: {
          _id: '$astrologerId',
          totalEarnings: { $sum: '$amount' },
          totalConsultations: { $sum: 1 }
        }
      },
      { $sort: { totalEarnings: -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: 'astrologers',
          localField: '_id',
          foreignField: '_id',
          as: 'astrologer'
        }
      },
      { $unwind: '$astrologer' },
      {
        $project: {
          name: '$astrologer.name',
          email: '$astrologer.email',
          profilePicture: '$astrologer.profilePicture',
          specialty: '$astrologer.specialty',
          totalEarnings: 1,
          totalConsultations: 1
        }
      }
    ]);

    // ============================================
    // 4. USER GROWTH TREND
    // ============================================
    const userGrowthTrend = await User.aggregate([
      {
        $match: {
          createdAt: { $gte: last3Months }
        }
      },
      {
        $group: {
          _id: groupBy,
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // ============================================
    // 5. ASTROLOGER GROWTH TREND
    // ============================================
    const astrologerGrowthTrend = await Astrologer.aggregate([
      {
        $match: {
          createdAt: { $gte: last3Months }
        }
      },
      {
        $group: {
          _id: groupBy,
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // ============================================
    // 6. CONSULTATION TREND
    // ============================================
    const consultationTrend = await Consultation.aggregate([
      {
        $match: {
          createdAt: { $gte: last3Months }
        }
      },
      {
        $group: {
          _id: groupBy,
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // ============================================
    // 7. SERVICE POPULARITY
    // ============================================
    const servicePopularity = await ServiceRequest.aggregate([
      {
        $group: {
          _id: '$serviceName',
          bookings: { $sum: 1 },
          revenue: { $sum: '$price' }
        }
      },
      { $sort: { bookings: -1 } },
      { $limit: 10 }
    ]);

    // ============================================
    // 8. CONSULTATION STATUS DISTRIBUTION
    // ============================================
    const consultationStatusDistribution = await Consultation.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    // ============================================
    // 9. REVIEW RATING DISTRIBUTION
    // ============================================
    const reviewRatingDistribution = await Review.aggregate([
      {
        $group: {
          _id: '$rating',
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // ============================================
    // 10. LIVE STREAM STATS
    // ============================================
    const liveStreamStats = await LiveStream.aggregate([
      {
        $group: {
          _id: null,
          totalViewers: { $sum: '$viewerCount' },
          totalViews: { $sum: '$totalViews' },
          avgViewers: { $avg: '$viewerCount' },
          totalLikes: { $sum: '$likes' }
        }
      }
    ]);

    // ============================================
    // RESPONSE
    // ============================================
    res.json({
      success: true,
      data: {
        overview: {
          revenue: {
            total: totalRevenue,
            today: todayRevenue,
            yesterday: yesterdayRevenue,
            week: weekRevenue,
            month: monthRevenue,
            growth: parseFloat(revenueGrowth)
          },
          consultations: {
            total: totalConsultations,
            today: todayConsultations,
            completed: completedConsultations,
            completionRate: totalConsultations > 0 
              ? ((completedConsultations / totalConsultations) * 100).toFixed(1)
              : 0
          },
          users: {
            total: totalUsers,
            active: activeUsers,
            activeRate: totalUsers > 0 
              ? ((activeUsers / totalUsers) * 100).toFixed(1)
              : 0
          },
          astrologers: {
            total: totalAstrologers,
            active: activeAstrologers,
            activeRate: totalAstrologers > 0 
              ? ((activeAstrologers / totalAstrologers) * 100).toFixed(1)
              : 0
          },
          reviews: {
            total: totalReviews,
            averageRating: avgRating.toFixed(1)
          },
          services: {
            total: totalServices
          },
          liveStreams: {
            total: totalLiveStreams,
            active: activeLiveStreams
          }
        },
        trends: {
          revenue: revenueTrend,
          users: userGrowthTrend,
          astrologers: astrologerGrowthTrend,
          consultations: consultationTrend
        },
        topPerformers: {
          astrologers: topAstrologers,
          services: servicePopularity
        },
        distributions: {
          consultationStatus: consultationStatusDistribution,
          reviewRatings: reviewRatingDistribution
        },
        liveStreamStats: liveStreamStats[0] || {
          totalViewers: 0,
          totalViews: 0,
          avgViewers: 0,
          totalLikes: 0
        }
      }
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch analytics data',
      error: error.message
    });
  }
});

module.exports = router;


