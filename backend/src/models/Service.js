const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  // Basic service information
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    required: true,
    trim: true,
    maxlength: 1000
  },
  category: {
    type: String,
    required: true,
    enum: [
      'e_pooja',
      'reiki_healing', 
      'evil_eye_removal',
      'vastu_shastra',
      'gemstone_consultation',
      'yantra',
      'astrology',
      'numerology',
      'tarot',
      'other'
    ],
    default: 'e_pooja'
  },
  
  // Pricing
  price: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'INR',
    enum: ['INR', 'USD', 'EUR']
  },
  
  // Duration (in minutes or descriptive)
  duration: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  durationMinutes: {
    type: Number,
    min: 15,
    max: 480 // Max 8 hours
  },
  
  // Requirements and benefits
  requirements: {
    type: String,
    trim: true,
    maxlength: 500
  },
  benefits: [{
    type: String,
    trim: true,
    maxlength: 200
  }],
  
  // Media
  imageUrl: {
    type: String,
    trim: true
  },
  images: [{
    type: String,
    trim: true
  }],
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Astrologer reference
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true
  },
  
  // Availability settings
  availability: {
    availableDays: [{
      type: Number,
      min: 0,
      max: 6 // 0 = Sunday, 6 = Saturday
    }],
    startTime: {
      type: String,
      default: '09:00'
    },
    endTime: {
      type: String,
      default: '18:00'
    },
    maxBookingsPerDay: {
      type: Number,
      default: 10,
      min: 1
    }
  },
  
  // Statistics
  totalBookings: {
    type: Number,
    default: 0,
    min: 0
  },
  completedBookings: {
    type: Number,
    default: 0,
    min: 0
  },
  averageRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  totalRatings: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // SEO and discovery
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  
  // Soft delete
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Indexes for better query performance
serviceSchema.index({ astrologerId: 1, isActive: 1 });
serviceSchema.index({ category: 1, isActive: 1 });
serviceSchema.index({ isActive: 1, isDeleted: 1 });
serviceSchema.index({ price: 1 });
serviceSchema.index({ averageRating: -1 });
serviceSchema.index({ tags: 1 });
serviceSchema.index({ createdAt: -1 });

// Compound indexes
serviceSchema.index({ astrologerId: 1, category: 1, isActive: 1 });

// Virtual for category display name
serviceSchema.virtual('categoryDisplay').get(function() {
  const categoryMap = {
    'e_pooja': 'E-Pooja',
    'reiki_healing': 'Reiki Healing',
    'evil_eye_removal': 'Evil Eye Removal',
    'vastu_shastra': 'Vastu Shastra',
    'gemstone_consultation': 'Gemstone Consultation',
    'yantra': 'Yantra',
    'astrology': 'Astrology',
    'numerology': 'Numerology',
    'tarot': 'Tarot Reading',
    'other': 'Other Services'
  };
  return categoryMap[this.category] || this.category;
});

// Instance methods
serviceSchema.methods.toggleActive = function() {
  this.isActive = !this.isActive;
  return this.save();
};

serviceSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.isActive = false;
  return this.save();
};

serviceSchema.methods.incrementBookings = function() {
  this.totalBookings += 1;
  return this.save();
};

serviceSchema.methods.incrementCompleted = function() {
  this.completedBookings += 1;
  return this.save();
};

serviceSchema.methods.updateRating = function(newRating) {
  const totalRatingSum = this.averageRating * this.totalRatings;
  this.totalRatings += 1;
  this.averageRating = (totalRatingSum + newRating) / this.totalRatings;
  return this.save();
};

// Static methods
serviceSchema.statics.getActiveServices = function(astrologerId) {
  return this.find({
    astrologerId,
    isActive: true,
    isDeleted: false
  }).sort({ createdAt: -1 });
};

serviceSchema.statics.getServicesByCategory = function(astrologerId, category) {
  return this.find({
    astrologerId,
    category,
    isActive: true,
    isDeleted: false
  }).sort({ createdAt: -1 });
};

serviceSchema.statics.getPopularServices = function(astrologerId, limit = 5) {
  return this.find({
    astrologerId,
    isActive: true,
    isDeleted: false
  })
  .sort({ totalBookings: -1, averageRating: -1 })
  .limit(limit);
};

serviceSchema.statics.searchServices = function(astrologerId, query) {
  return this.find({
    astrologerId,
    isActive: true,
    isDeleted: false,
    $or: [
      { name: { $regex: query, $options: 'i' } },
      { description: { $regex: query, $options: 'i' } },
      { tags: { $regex: query, $options: 'i' } }
    ]
  });
};

// For end user app - browse all active services
serviceSchema.statics.browseServices = function(filters = {}) {
  const query = {
    isActive: true,
    isDeleted: false
  };
  
  if (filters.category) {
    query.category = filters.category;
  }
  
  if (filters.minPrice !== undefined) {
    query.price = { ...query.price, $gte: filters.minPrice };
  }
  
  if (filters.maxPrice !== undefined) {
    query.price = { ...query.price, $lte: filters.maxPrice };
  }
  
  let sortOption = { createdAt: -1 };
  if (filters.sortBy === 'price_low') {
    sortOption = { price: 1 };
  } else if (filters.sortBy === 'price_high') {
    sortOption = { price: -1 };
  } else if (filters.sortBy === 'rating') {
    sortOption = { averageRating: -1 };
  } else if (filters.sortBy === 'popular') {
    sortOption = { totalBookings: -1 };
  }
  
  return this.find(query)
    .populate('astrologerId', 'name profileImage rating')
    .sort(sortOption);
};

module.exports = mongoose.model('Service', serviceSchema);

