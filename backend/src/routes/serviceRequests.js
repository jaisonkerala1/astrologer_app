const express = require('express');
const router = express.Router();
const ServiceRequest = require('../models/ServiceRequest');
const Service = require('../models/Service');
const auth = require('../middleware/auth');
const rateLimit = require('express-rate-limit');
const {
  broadcastNewServiceRequest,
  broadcastServiceRequestStatus,
  broadcastServiceRequestNotes,
  broadcastServiceRequestDelete,
} = require('../socket/handlers/serviceRequestHandler');

// Rate limiting
const requestLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Too many requests, please try again later.'
});

// ============================================================================
// ASTROLOGER ROUTES (Protected)
// ============================================================================

/**
 * GET /api/service-requests
 * Get all service requests for the authenticated astrologer
 */
router.get('/', auth, async (req, res) => {
  try {
    const { 
      status, 
      fromDate, 
      toDate, 
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    const query = {
      astrologerId: req.user.astrologerId,
      isDeleted: false
    };
    
    if (status) {
      query.status = status;
    }
    
    if (fromDate) {
      query.requestedDate = { ...query.requestedDate, $gte: new Date(fromDate) };
    }
    
    if (toDate) {
      query.requestedDate = { ...query.requestedDate, $lte: new Date(toDate) };
    }
    
    if (search) {
      query.$or = [
        { customerName: { $regex: search, $options: 'i' } },
        { customerPhone: { $regex: search, $options: 'i' } },
        { serviceName: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const [requests, total] = await Promise.all([
      ServiceRequest.find(query)
        .populate('serviceId', 'name category imageUrl')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      ServiceRequest.countDocuments(query)
    ]);
    
    // Transform for frontend compatibility
    const transformedRequests = requests.map(req => ({
      id: req._id.toString(),
      customerName: req.customerName,
      customerPhone: req.customerPhone,
      customerEmail: req.customerEmail || '',
      serviceName: req.serviceName,
      serviceCategory: req.serviceCategory,
      serviceId: req.serviceId?._id?.toString() || null,
      requestedDate: req.requestedDate.toISOString(),
      requestedTime: req.requestedTime,
      status: req.status,
      statusDisplay: req.statusDisplay,
      statusColor: req.statusColor,
      price: req.price,
      currency: req.currency,
      specialInstructions: req.specialInstructions || '',
      notes: req.notes || '',
      isManual: req.isManual,
      source: req.source,
      rating: req.rating,
      feedback: req.feedback,
      confirmedAt: req.confirmedAt?.toISOString() || null,
      startedAt: req.startedAt?.toISOString() || null,
      completedAt: req.completedAt?.toISOString() || null,
      cancelledAt: req.cancelledAt?.toISOString() || null,
      createdAt: req.createdAt.toISOString(),
      updatedAt: req.updatedAt.toISOString()
    }));
    
    res.json({
      success: true,
      data: {
        requests: transformedRequests,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching service requests:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching service requests',
      error: error.message
    });
  }
});

/**
 * GET /api/service-requests/:id
 * Get single service request by ID
 */
router.get('/:id', auth, async (req, res) => {
  try {
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    }).populate('serviceId', 'name category imageUrl price duration');
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        id: request._id.toString(),
        customerName: request.customerName,
        customerPhone: request.customerPhone,
        customerEmail: request.customerEmail || '',
        serviceName: request.serviceName,
        serviceCategory: request.serviceCategory,
        serviceId: request.serviceId?._id?.toString() || null,
        service: request.serviceId ? {
          id: request.serviceId._id.toString(),
          name: request.serviceId.name,
          category: request.serviceId.category,
          imageUrl: request.serviceId.imageUrl,
          price: request.serviceId.price,
          duration: request.serviceId.duration
        } : null,
        requestedDate: request.requestedDate.toISOString(),
        requestedTime: request.requestedTime,
        status: request.status,
        statusDisplay: request.statusDisplay,
        statusColor: request.statusColor,
        price: request.price,
        currency: request.currency,
        specialInstructions: request.specialInstructions || '',
        notes: request.notes || '',
        statusHistory: request.statusHistory.map(h => ({
          status: h.status,
          timestamp: h.timestamp.toISOString(),
          notes: h.notes || ''
        })),
        isManual: request.isManual,
        source: request.source,
        rating: request.rating,
        feedback: request.feedback,
        confirmedAt: request.confirmedAt?.toISOString() || null,
        startedAt: request.startedAt?.toISOString() || null,
        completedAt: request.completedAt?.toISOString() || null,
        cancelledAt: request.cancelledAt?.toISOString() || null,
        createdAt: request.createdAt.toISOString(),
        updatedAt: request.updatedAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Error fetching service request:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching service request',
      error: error.message
    });
  }
});

/**
 * POST /api/service-requests
 * Create a new service request (manual entry by astrologer)
 */
router.post('/', auth, requestLimiter, async (req, res) => {
  try {
    const {
      customerName,
      customerPhone,
      customerEmail,
      serviceName,
      serviceCategory,
      serviceId,
      requestedDate,
      requestedTime,
      price,
      currency,
      specialInstructions,
      notes
    } = req.body;
    
    // Validation
    if (!customerName || !customerPhone || !serviceName || !serviceCategory || !requestedDate || !requestedTime || price === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: customerName, customerPhone, serviceName, serviceCategory, requestedDate, requestedTime, price'
      });
    }
    
    const request = new ServiceRequest({
      customerName,
      customerPhone,
      customerEmail,
      serviceName,
      serviceCategory,
      serviceId: serviceId || null,
      requestedDate: new Date(requestedDate),
      requestedTime,
      price,
      currency: currency || 'INR',
      specialInstructions,
      notes,
      status: 'pending',
      isManual: true,
      source: 'astrologer_app',
      astrologerId: req.user.astrologerId
    });
    
    await request.save();
    
    // Update service booking count if linked
    if (serviceId) {
      await Service.findByIdAndUpdate(serviceId, {
        $inc: { totalBookings: 1 }
      });
    }
    
    // Broadcast real-time update via Socket.IO
    const io = req.app.get('io');
    if (io) {
      broadcastNewServiceRequest(io, req.user.astrologerId, request);
    }
    
    res.status(201).json({
      success: true,
      message: 'Service request created successfully',
      data: {
        id: request._id.toString(),
        customerName: request.customerName,
        serviceName: request.serviceName,
        status: request.status,
        requestedDate: request.requestedDate.toISOString(),
        requestedTime: request.requestedTime,
        price: request.price,
        createdAt: request.createdAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Error creating service request:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating service request',
      error: error.message
    });
  }
});

/**
 * PUT /api/service-requests/:id/status
 * Update service request status
 */
router.put('/:id/status', auth, async (req, res) => {
  try {
    const { status, notes, cancelledBy, cancellationReason } = req.body;
    
    const validStatuses = ['pending', 'confirmed', 'inProgress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }
    
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }
    
    await request.updateStatus(status, { notes, cancelledBy, cancellationReason });
    
    // Broadcast real-time update via Socket.IO
    const io = req.app.get('io');
    if (io) {
      broadcastServiceRequestStatus(io, req.user.astrologerId, request);
      
      // If user is connected, notify them too
      if (request.userId) {
        io.to(`user:${request.userId}`).emit('service-request:status', {
          requestId: request._id.toString(),
          status: request.status,
          statusDisplay: request.statusDisplay
        });
      }
    }
    
    res.json({
      success: true,
      message: 'Status updated successfully',
      data: {
        id: request._id.toString(),
        status: request.status,
        statusDisplay: request.statusDisplay,
        confirmedAt: request.confirmedAt?.toISOString() || null,
        startedAt: request.startedAt?.toISOString() || null,
        completedAt: request.completedAt?.toISOString() || null,
        cancelledAt: request.cancelledAt?.toISOString() || null
      }
    });
  } catch (error) {
    console.error('Error updating status:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating status',
      error: error.message
    });
  }
});

/**
 * PUT /api/service-requests/:id/notes
 * Add/update notes for a service request
 */
router.put('/:id/notes', auth, async (req, res) => {
  try {
    const { notes } = req.body;
    
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }
    
    await request.addNotes(notes);
    
    // Broadcast real-time update via Socket.IO
    const io = req.app.get('io');
    if (io) {
      broadcastServiceRequestNotes(io, req.user.astrologerId, request);
    }
    
    res.json({
      success: true,
      message: 'Notes updated successfully',
      data: {
        id: request._id.toString(),
        notes: request.notes
      }
    });
  } catch (error) {
    console.error('Error updating notes:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating notes',
      error: error.message
    });
  }
});

/**
 * DELETE /api/service-requests/:id
 * Soft delete a service request
 */
router.delete('/:id', auth, async (req, res) => {
  try {
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }
    
    await request.softDelete();
    
    // Broadcast real-time update via Socket.IO
    const io = req.app.get('io');
    if (io) {
      broadcastServiceRequestDelete(io, req.user.astrologerId, request._id.toString());
    }
    
    res.json({
      success: true,
      message: 'Service request deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting service request:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting service request',
      error: error.message
    });
  }
});

/**
 * GET /api/service-requests/stats/summary
 * Get service request statistics
 */
router.get('/stats/summary', auth, async (req, res) => {
  try {
    const astrologerId = req.user.astrologerId;
    
    const [statusStats, todaysRequests, earnings] = await Promise.all([
      ServiceRequest.getStatistics(astrologerId),
      ServiceRequest.getTodaysRequests(astrologerId),
      ServiceRequest.getEarnings(astrologerId)
    ]);
    
    // Transform status stats
    const stats = {
      pending: 0,
      confirmed: 0,
      inProgress: 0,
      completed: 0,
      cancelled: 0,
      total: 0
    };
    
    statusStats.forEach(s => {
      stats[s._id] = s.count;
      stats.total += s.count;
    });
    
    res.json({
      success: true,
      data: {
        statusBreakdown: stats,
        todaysCount: todaysRequests.length,
        todaysRequests: todaysRequests.slice(0, 5).map(r => ({
          id: r._id.toString(),
          customerName: r.customerName,
          serviceName: r.serviceName,
          requestedTime: r.requestedTime,
          status: r.status
        })),
        totalEarnings: earnings[0]?.totalEarnings || 0,
        completedCount: earnings[0]?.count || 0
      }
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching statistics',
      error: error.message
    });
  }
});

// ============================================================================
// USER ROUTES (For end user app)
// ============================================================================

/**
 * POST /api/service-requests/user/book
 * Book a service (from end user app)
 * Note: This would require user authentication middleware
 */
router.post('/user/book', requestLimiter, async (req, res) => {
  try {
    const {
      serviceId,
      customerName,
      customerPhone,
      customerEmail,
      requestedDate,
      requestedTime,
      specialInstructions,
      userId // Would come from user auth
    } = req.body;
    
    // Validation
    if (!serviceId || !customerName || !customerPhone || !requestedDate || !requestedTime) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }
    
    // Get service details
    const service = await Service.findOne({
      _id: serviceId,
      isActive: true,
      isDeleted: false
    });
    
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found or not available'
      });
    }
    
    const request = new ServiceRequest({
      customerName,
      customerPhone,
      customerEmail,
      serviceName: service.name,
      serviceCategory: service.category,
      serviceId: service._id,
      astrologerId: service.astrologerId,
      userId: userId || null,
      requestedDate: new Date(requestedDate),
      requestedTime,
      price: service.price,
      currency: service.currency,
      specialInstructions,
      status: 'pending',
      isManual: false,
      source: 'user_app'
    });
    
    await request.save();
    
    // Update service booking count
    await service.incrementBookings();
    
    // Broadcast real-time update via Socket.IO
    const io = req.app.get('io');
    if (io) {
      broadcastNewServiceRequest(io, service.astrologerId.toString(), request);
    }
    
    res.status(201).json({
      success: true,
      message: 'Service booked successfully',
      data: {
        id: request._id.toString(),
        serviceName: request.serviceName,
        astrologerId: request.astrologerId.toString(),
        requestedDate: request.requestedDate.toISOString(),
        requestedTime: request.requestedTime,
        price: request.price,
        status: request.status
      }
    });
  } catch (error) {
    console.error('Error booking service:', error);
    res.status(500).json({
      success: false,
      message: 'Error booking service',
      error: error.message
    });
  }
});

/**
 * GET /api/service-requests/user/my-bookings
 * Get user's bookings (for end user app)
 */
router.get('/user/my-bookings', async (req, res) => {
  try {
    const { userId, status, page = 1, limit = 20 } = req.query;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID required'
      });
    }
    
    const query = {
      userId,
      isDeleted: false
    };
    
    if (status) {
      query.status = status;
    }
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const [bookings, total] = await Promise.all([
      ServiceRequest.find(query)
        .populate('astrologerId', 'name profileImage rating')
        .populate('serviceId', 'name category imageUrl')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      ServiceRequest.countDocuments(query)
    ]);
    
    const transformedBookings = bookings.map(b => ({
      id: b._id.toString(),
      serviceName: b.serviceName,
      serviceCategory: b.serviceCategory,
      requestedDate: b.requestedDate.toISOString(),
      requestedTime: b.requestedTime,
      status: b.status,
      statusDisplay: b.statusDisplay,
      price: b.price,
      astrologer: b.astrologerId ? {
        id: b.astrologerId._id.toString(),
        name: b.astrologerId.name,
        profileImage: b.astrologerId.profileImage
      } : null,
      service: b.serviceId ? {
        id: b.serviceId._id.toString(),
        name: b.serviceId.name,
        imageUrl: b.serviceId.imageUrl
      } : null,
      createdAt: b.createdAt.toISOString()
    }));
    
    res.json({
      success: true,
      data: {
        bookings: transformedBookings,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching bookings',
      error: error.message
    });
  }
});

/**
 * PUT /api/service-requests/user/:id/cancel
 * Cancel a booking (from end user app)
 */
router.put('/user/:id/cancel', async (req, res) => {
  try {
    const { userId, cancellationReason } = req.body;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID required'
      });
    }
    
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      userId,
      status: { $in: ['pending', 'confirmed'] },
      isDeleted: false
    });
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found or cannot be cancelled'
      });
    }
    
    await request.updateStatus('cancelled', {
      cancelledBy: 'customer',
      cancellationReason
    });
    
    // Notify astrologer
    const io = req.app.get('io');
    if (io) {
      io.to(`astrologer:${request.astrologerId}`).emit('service-request:cancelled', {
        requestId: request._id.toString(),
        customerName: request.customerName,
        serviceName: request.serviceName,
        cancelledBy: 'customer'
      });
    }
    
    res.json({
      success: true,
      message: 'Booking cancelled successfully'
    });
  } catch (error) {
    console.error('Error cancelling booking:', error);
    res.status(500).json({
      success: false,
      message: 'Error cancelling booking',
      error: error.message
    });
  }
});

/**
 * PUT /api/service-requests/user/:id/rate
 * Rate a completed service (from end user app)
 */
router.put('/user/:id/rate', async (req, res) => {
  try {
    const { userId, rating, feedback } = req.body;
    
    if (!userId || !rating) {
      return res.status(400).json({
        success: false,
        message: 'User ID and rating required'
      });
    }
    
    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }
    
    const request = await ServiceRequest.findOne({
      _id: req.params.id,
      userId,
      status: 'completed',
      isDeleted: false,
      rating: { $exists: false }
    });
    
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found or already rated'
      });
    }
    
    await request.addRating(rating, feedback);
    
    res.json({
      success: true,
      message: 'Rating submitted successfully',
      data: {
        id: request._id.toString(),
        rating: request.rating,
        feedback: request.feedback
      }
    });
  } catch (error) {
    console.error('Error rating service:', error);
    res.status(500).json({
      success: false,
      message: 'Error submitting rating',
      error: error.message
    });
  }
});

module.exports = router;

