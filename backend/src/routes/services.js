const express = require('express');
const router = express.Router();
const Service = require('../models/Service');
const { auth } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

// Rate limiting for service operations
const serviceLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30,
  message: 'Too many requests, please try again later.'
});

// ============================================================================
// ASTROLOGER ROUTES (Protected)
// ============================================================================

/**
 * GET /api/services
 * Get all services for the authenticated astrologer
 */
router.get('/', auth, async (req, res) => {
  try {
    const { category, isActive, search, page = 1, limit = 20 } = req.query;
    
    const query = {
      astrologerId: req.user.astrologerId,
      isDeleted: false
    };
    
    if (category) {
      query.category = category;
    }
    
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const [services, total] = await Promise.all([
      Service.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Service.countDocuments(query)
    ]);
    
    // Transform for frontend compatibility
    const transformedServices = services.map(service => ({
      id: service._id.toString(),
      name: service.name,
      description: service.description,
      category: service.category,
      categoryDisplay: service.categoryDisplay,
      price: service.price,
      currency: service.currency,
      duration: service.duration,
      durationMinutes: service.durationMinutes,
      requirements: service.requirements || '',
      benefits: service.benefits || [],
      imageUrl: service.imageUrl || '',
      images: service.images || [],
      isActive: service.isActive,
      availability: service.availability,
      totalBookings: service.totalBookings,
      completedBookings: service.completedBookings,
      averageRating: service.averageRating,
      totalRatings: service.totalRatings,
      tags: service.tags || [],
      createdAt: service.createdAt.toISOString(),
      updatedAt: service.updatedAt.toISOString()
    }));
    
    res.json({
      success: true,
      data: {
        services: transformedServices,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching services:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching services',
      error: error.message
    });
  }
});

/**
 * GET /api/services/:id
 * Get single service by ID
 */
router.get('/:id', auth, async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        id: service._id.toString(),
        name: service.name,
        description: service.description,
        category: service.category,
        categoryDisplay: service.categoryDisplay,
        price: service.price,
        currency: service.currency,
        duration: service.duration,
        durationMinutes: service.durationMinutes,
        requirements: service.requirements || '',
        benefits: service.benefits || [],
        imageUrl: service.imageUrl || '',
        images: service.images || [],
        isActive: service.isActive,
        availability: service.availability,
        totalBookings: service.totalBookings,
        completedBookings: service.completedBookings,
        averageRating: service.averageRating,
        totalRatings: service.totalRatings,
        tags: service.tags || [],
        createdAt: service.createdAt.toISOString(),
        updatedAt: service.updatedAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Error fetching service:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching service',
      error: error.message
    });
  }
});

/**
 * POST /api/services
 * Create a new service
 */
router.post('/', auth, serviceLimiter, async (req, res) => {
  try {
    const {
      name,
      description,
      category,
      price,
      currency,
      duration,
      durationMinutes,
      requirements,
      benefits,
      imageUrl,
      images,
      isActive,
      availability,
      tags
    } = req.body;
    
    // Validation
    if (!name || !description || !category || price === undefined || !duration) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: name, description, category, price, duration'
      });
    }
    
    const service = new Service({
      name,
      description,
      category,
      price,
      currency: currency || 'INR',
      duration,
      durationMinutes,
      requirements,
      benefits: benefits || [],
      imageUrl,
      images: images || [],
      isActive: isActive !== undefined ? isActive : true,
      availability: availability || {
        availableDays: [1, 2, 3, 4, 5], // Mon-Fri default
        startTime: '09:00',
        endTime: '18:00',
        maxBookingsPerDay: 10
      },
      tags: tags || [],
      astrologerId: req.user.astrologerId
    });
    
    await service.save();
    
    res.status(201).json({
      success: true,
      message: 'Service created successfully',
      data: {
        id: service._id.toString(),
        name: service.name,
        description: service.description,
        category: service.category,
        price: service.price,
        duration: service.duration,
        isActive: service.isActive,
        createdAt: service.createdAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Error creating service:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating service',
      error: error.message
    });
  }
});

/**
 * PUT /api/services/:id
 * Update a service
 */
router.put('/:id', auth, serviceLimiter, async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }
    
    const allowedUpdates = [
      'name', 'description', 'category', 'price', 'currency',
      'duration', 'durationMinutes', 'requirements', 'benefits',
      'imageUrl', 'images', 'isActive', 'availability', 'tags'
    ];
    
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        service[field] = req.body[field];
      }
    });
    
    await service.save();
    
    res.json({
      success: true,
      message: 'Service updated successfully',
      data: {
        id: service._id.toString(),
        name: service.name,
        description: service.description,
        category: service.category,
        price: service.price,
        duration: service.duration,
        isActive: service.isActive,
        updatedAt: service.updatedAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Error updating service:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating service',
      error: error.message
    });
  }
});

/**
 * PATCH /api/services/:id/toggle
 * Toggle service active status
 */
router.patch('/:id/toggle', auth, async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }
    
    await service.toggleActive();
    
    res.json({
      success: true,
      message: `Service ${service.isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        id: service._id.toString(),
        isActive: service.isActive
      }
    });
  } catch (error) {
    console.error('Error toggling service status:', error);
    res.status(500).json({
      success: false,
      message: 'Error toggling service status',
      error: error.message
    });
  }
});

/**
 * DELETE /api/services/:id
 * Soft delete a service
 */
router.delete('/:id', auth, async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      astrologerId: req.user.astrologerId,
      isDeleted: false
    });
    
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
    console.error('Error deleting service:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting service',
      error: error.message
    });
  }
});

/**
 * GET /api/services/stats/summary
 * Get service statistics for the astrologer
 */
router.get('/stats/summary', auth, async (req, res) => {
  try {
    const astrologerId = req.user.astrologerId;
    
    const [totalServices, activeServices, categoryStats] = await Promise.all([
      Service.countDocuments({ astrologerId, isDeleted: false }),
      Service.countDocuments({ astrologerId, isActive: true, isDeleted: false }),
      Service.aggregate([
        { $match: { astrologerId: astrologerId, isDeleted: false } },
        { $group: { _id: '$category', count: { $sum: 1 }, totalBookings: { $sum: '$totalBookings' } } }
      ])
    ]);
    
    res.json({
      success: true,
      data: {
        totalServices,
        activeServices,
        inactiveServices: totalServices - activeServices,
        categoryBreakdown: categoryStats
      }
    });
  } catch (error) {
    console.error('Error fetching service stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching statistics',
      error: error.message
    });
  }
});

// ============================================================================
// PUBLIC/USER ROUTES (For end user app)
// ============================================================================

/**
 * GET /api/services/browse/all
 * Browse all available services (for end user app)
 * No authentication required
 */
router.get('/browse/all', async (req, res) => {
  try {
    const { 
      category, 
      minPrice, 
      maxPrice, 
      sortBy = 'popular',
      page = 1, 
      limit = 20 
    } = req.query;
    
    const query = {
      isActive: true,
      isDeleted: false
    };
    
    if (category) {
      query.category = category;
    }
    
    if (minPrice) {
      query.price = { ...query.price, $gte: parseFloat(minPrice) };
    }
    
    if (maxPrice) {
      query.price = { ...query.price, $lte: parseFloat(maxPrice) };
    }
    
    let sortOption = { totalBookings: -1 }; // Default: popular
    if (sortBy === 'price_low') sortOption = { price: 1 };
    else if (sortBy === 'price_high') sortOption = { price: -1 };
    else if (sortBy === 'rating') sortOption = { averageRating: -1 };
    else if (sortBy === 'newest') sortOption = { createdAt: -1 };
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const [services, total] = await Promise.all([
      Service.find(query)
        .populate('astrologerId', 'name profileImage rating specializations')
        .sort(sortOption)
        .skip(skip)
        .limit(parseInt(limit)),
      Service.countDocuments(query)
    ]);
    
    const transformedServices = services.map(service => ({
      id: service._id.toString(),
      name: service.name,
      description: service.description,
      category: service.category,
      categoryDisplay: service.categoryDisplay,
      price: service.price,
      currency: service.currency,
      duration: service.duration,
      imageUrl: service.imageUrl || '',
      averageRating: service.averageRating,
      totalRatings: service.totalRatings,
      totalBookings: service.totalBookings,
      astrologer: service.astrologerId ? {
        id: service.astrologerId._id.toString(),
        name: service.astrologerId.name,
        profileImage: service.astrologerId.profileImage,
        rating: service.astrologerId.rating
      } : null
    }));
    
    res.json({
      success: true,
      data: {
        services: transformedServices,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error browsing services:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching services',
      error: error.message
    });
  }
});

/**
 * GET /api/services/browse/:id
 * Get single service details for end user
 */
router.get('/browse/:id', async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      isActive: true,
      isDeleted: false
    }).populate('astrologerId', 'name profileImage rating specializations bio experience');
    
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        id: service._id.toString(),
        name: service.name,
        description: service.description,
        category: service.category,
        categoryDisplay: service.categoryDisplay,
        price: service.price,
        currency: service.currency,
        duration: service.duration,
        requirements: service.requirements || '',
        benefits: service.benefits || [],
        imageUrl: service.imageUrl || '',
        images: service.images || [],
        availability: service.availability,
        averageRating: service.averageRating,
        totalRatings: service.totalRatings,
        totalBookings: service.totalBookings,
        astrologer: service.astrologerId ? {
          id: service.astrologerId._id.toString(),
          name: service.astrologerId.name,
          profileImage: service.astrologerId.profileImage,
          rating: service.astrologerId.rating,
          specializations: service.astrologerId.specializations,
          bio: service.astrologerId.bio,
          experience: service.astrologerId.experience
        } : null
      }
    });
  } catch (error) {
    console.error('Error fetching service details:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching service details',
      error: error.message
    });
  }
});

/**
 * GET /api/services/categories/list
 * Get list of service categories
 */
router.get('/categories/list', async (req, res) => {
  try {
    const categories = [
      { id: 'e_pooja', name: 'E-Pooja', icon: '🕉️', color: '#FF6B6B' },
      { id: 'reiki_healing', name: 'Reiki Healing', icon: '✨', color: '#4ECDC4' },
      { id: 'evil_eye_removal', name: 'Evil Eye Removal', icon: '👁️', color: '#45B7D1' },
      { id: 'vastu_shastra', name: 'Vastu Shastra', icon: '🏠', color: '#96CEB4' },
      { id: 'gemstone_consultation', name: 'Gemstone Consultation', icon: '💎', color: '#FFEAA7' },
      { id: 'yantra', name: 'Yantra', icon: '🔯', color: '#DDA0DD' },
      { id: 'astrology', name: 'Astrology', icon: '⭐', color: '#FFB347' },
      { id: 'numerology', name: 'Numerology', icon: '🔢', color: '#87CEEB' },
      { id: 'tarot', name: 'Tarot Reading', icon: '🃏', color: '#DDA0DD' },
      { id: 'other', name: 'Other Services', icon: '🔮', color: '#C0C0C0' }
    ];
    
    res.json({
      success: true,
      data: categories
    });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
});

module.exports = router;

