const mongoose = require('mongoose');

const serviceRequestSchema = new mongoose.Schema({
  // Customer information
  customerName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  customerPhone: {
    type: String,
    required: true,
    trim: true,
    maxlength: 15
  },
  customerEmail: {
    type: String,
    trim: true,
    lowercase: true,
    maxlength: 100
  },
  
  // Service information
  serviceName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  serviceCategory: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  
  // References
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true
  },
  serviceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service'
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User' // For end user app bookings
  },
  
  // Scheduling
  requestedDate: {
    type: Date,
    required: true
  },
  requestedTime: {
    type: String,
    required: true,
    trim: true
  },
  
  // Status
  status: {
    type: String,
    required: true,
    enum: ['pending', 'confirmed', 'inProgress', 'completed', 'cancelled'],
    default: 'pending'
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
  
  // Additional information
  specialInstructions: {
    type: String,
    trim: true,
    maxlength: 500
  },
  notes: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  
  // Timestamps for status changes
  confirmedAt: {
    type: Date
  },
  startedAt: {
    type: Date
  },
  completedAt: {
    type: Date
  },
  cancelledAt: {
    type: Date
  },
  cancelledBy: {
    type: String,
    enum: ['astrologer', 'customer', 'system']
  },
  cancellationReason: {
    type: String,
    trim: true,
    maxlength: 200
  },
  
  // Status history tracking
  statusHistory: [{
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'inProgress', 'completed', 'cancelled'],
      required: true
    },
    timestamp: {
      type: Date,
      default: Date.now
    },
    notes: {
      type: String,
      trim: true
    }
  }],
  
  // Rating and feedback (from customer)
  rating: {
    type: Number,
    min: 1,
    max: 5
  },
  feedback: {
    type: String,
    trim: true,
    maxlength: 500
  },
  ratedAt: {
    type: Date
  },
  
  // Astrologer's rating of customer
  customerRating: {
    type: Number,
    min: 1,
    max: 5
  },
  customerFeedback: {
    type: String,
    trim: true,
    maxlength: 500
  },
  
  // Source tracking
  isManual: {
    type: Boolean,
    default: true // true = created by astrologer, false = created by end user
  },
  source: {
    type: String,
    enum: ['astrologer_app', 'user_app', 'website', 'admin'],
    default: 'astrologer_app'
  },
  
  // Payment info (for future)
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'refunded', 'failed'],
    default: 'pending'
  },
  paymentId: {
    type: String
  },
  
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
serviceRequestSchema.index({ astrologerId: 1, status: 1 });
serviceRequestSchema.index({ astrologerId: 1, requestedDate: -1 });
serviceRequestSchema.index({ astrologerId: 1, createdAt: -1 });
serviceRequestSchema.index({ userId: 1, status: 1 });
serviceRequestSchema.index({ serviceId: 1 });
serviceRequestSchema.index({ status: 1 });
serviceRequestSchema.index({ requestedDate: 1 });
serviceRequestSchema.index({ customerPhone: 1 });
serviceRequestSchema.index({ isManual: 1 });

// Compound indexes
serviceRequestSchema.index({ astrologerId: 1, status: 1, requestedDate: 1 });

// Virtual for status display
serviceRequestSchema.virtual('statusDisplay').get(function() {
  const statusMap = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'inProgress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled'
  };
  return statusMap[this.status] || this.status;
});

// Virtual for status color
serviceRequestSchema.virtual('statusColor').get(function() {
  const colorMap = {
    'pending': '#8B5CF6', // Primary Purple (matches theme)
    'confirmed': '#4CAF50',
    'inProgress': '#2196F3',
    'completed': '#9C27B0',
    'cancelled': '#F44336'
  };
  return colorMap[this.status] || '#666666';
});

// Instance methods
serviceRequestSchema.methods.updateStatus = async function(newStatus, additionalData = {}) {
  const previousStatus = this.status;
  this.status = newStatus;
  
  // Add to status history
  this.statusHistory.push({
    status: newStatus,
    timestamp: new Date(),
    notes: additionalData.notes || `Status changed from ${previousStatus} to ${newStatus}`
  });
  
  // Update specific timestamps based on status
  if (newStatus === 'confirmed') {
    this.confirmedAt = new Date();
  } else if (newStatus === 'inProgress') {
    this.startedAt = new Date();
  } else if (newStatus === 'completed') {
    this.completedAt = new Date();
    
    // Update service statistics
    if (this.serviceId) {
      const Service = mongoose.model('Service');
      await Service.findByIdAndUpdate(this.serviceId, {
        $inc: { completedBookings: 1 }
      });
    }
  } else if (newStatus === 'cancelled') {
    this.cancelledAt = new Date();
    this.cancelledBy = additionalData.cancelledBy || 'astrologer';
    this.cancellationReason = additionalData.cancellationReason || '';
  }
  
  return this.save();
};

serviceRequestSchema.methods.addNotes = function(notes) {
  this.notes = notes;
  return this.save();
};

serviceRequestSchema.methods.addRating = function(rating, feedback = '') {
  this.rating = rating;
  this.feedback = feedback;
  this.ratedAt = new Date();
  
  // Update service rating if linked
  if (this.serviceId) {
    const Service = mongoose.model('Service');
    Service.findById(this.serviceId).then(service => {
      if (service) {
        service.updateRating(rating);
      }
    });
  }
  
  return this.save();
};

serviceRequestSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  return this.save();
};

// Static methods
serviceRequestSchema.statics.getByAstrologer = function(astrologerId, filters = {}) {
  const query = {
    astrologerId,
    isDeleted: false
  };
  
  if (filters.status) {
    query.status = filters.status;
  }
  
  if (filters.fromDate) {
    query.requestedDate = { ...query.requestedDate, $gte: filters.fromDate };
  }
  
  if (filters.toDate) {
    query.requestedDate = { ...query.requestedDate, $lte: filters.toDate };
  }
  
  return this.find(query)
    .populate('serviceId', 'name category')
    .sort({ createdAt: -1 });
};

serviceRequestSchema.statics.getByUser = function(userId, filters = {}) {
  const query = {
    userId,
    isDeleted: false
  };
  
  if (filters.status) {
    query.status = filters.status;
  }
  
  return this.find(query)
    .populate('astrologerId', 'name profileImage')
    .populate('serviceId', 'name category imageUrl')
    .sort({ createdAt: -1 });
};

serviceRequestSchema.statics.getPendingRequests = function(astrologerId) {
  return this.find({
    astrologerId,
    status: 'pending',
    isDeleted: false
  })
  .sort({ createdAt: -1 });
};

serviceRequestSchema.statics.getActiveRequests = function(astrologerId) {
  return this.find({
    astrologerId,
    status: { $in: ['pending', 'confirmed', 'inProgress'] },
    isDeleted: false
  })
  .sort({ requestedDate: 1 });
};

serviceRequestSchema.statics.getTodaysRequests = function(astrologerId) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  return this.find({
    astrologerId,
    requestedDate: {
      $gte: today,
      $lt: tomorrow
    },
    isDeleted: false
  }).sort({ requestedTime: 1 });
};

serviceRequestSchema.statics.getStatistics = function(astrologerId) {
  return this.aggregate([
    { 
      $match: { 
        astrologerId: new mongoose.Types.ObjectId(astrologerId),
        isDeleted: false 
      } 
    },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalAmount: { $sum: '$price' }
      }
    }
  ]);
};

serviceRequestSchema.statics.getEarnings = function(astrologerId, startDate, endDate) {
  const matchCriteria = {
    astrologerId: new mongoose.Types.ObjectId(astrologerId),
    status: 'completed',
    isDeleted: false
  };
  
  if (startDate && endDate) {
    matchCriteria.completedAt = {
      $gte: startDate,
      $lte: endDate
    };
  }
  
  return this.aggregate([
    { $match: matchCriteria },
    { 
      $group: { 
        _id: null, 
        totalEarnings: { $sum: '$price' },
        count: { $sum: 1 }
      } 
    }
  ]);
};

// Pre-save middleware
serviceRequestSchema.pre('save', function(next) {
  // Add initial status to history if new document
  if (this.isNew) {
    this.statusHistory.push({
      status: this.status,
      timestamp: new Date(),
      notes: 'Request created'
    });
  }
  
  next();
});

module.exports = mongoose.model('ServiceRequest', serviceRequestSchema);

