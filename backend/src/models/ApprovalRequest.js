const mongoose = require('mongoose');

const approvalRequestSchema = new mongoose.Schema({
  // Astrologer reference
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true,
    index: true
  },
  
  // Denormalized astrologer data for faster queries
  astrologerName: {
    type: String,
    required: true,
    trim: true
  },
  astrologerEmail: {
    type: String,
    required: true,
    trim: true,
    lowercase: true
  },
  astrologerPhone: {
    type: String,
    required: true,
    trim: true
  },
  astrologerAvatar: {
    type: String,
    default: null
  },
  
  // Request type
  requestType: {
    type: String,
    required: true,
    enum: ['verification_badge', 'service_approval'],
    index: true
  },
  
  // Service reference (only for service_approval type)
  serviceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service',
    default: null
  },
  serviceName: {
    type: String,
    default: null,
    trim: true
  },
  
  // Status
  status: {
    type: String,
    required: true,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
    index: true
  },
  
  // Timestamps
  submittedAt: {
    type: Date,
    required: true,
    default: Date.now
  },
  reviewedAt: {
    type: Date,
    default: null
  },
  reviewedBy: {
    type: String,
    default: null,
    trim: true
  },
  
  // Rejection details
  rejectionReason: {
    type: String,
    default: null,
    trim: true,
    maxlength: 500
  },
  
  // Admin notes
  notes: {
    type: String,
    default: null,
    trim: true,
    maxlength: 1000
  },
  
  // Snapshot of astrologer data at submission time
  astrologerData: {
    experience: {
      type: Number,
      required: true,
      min: 0
    },
    specializations: [{
      type: String,
      trim: true
    }],
    consultationsCount: {
      type: Number,
      required: true,
      min: 0,
      default: 0
    },
    rating: {
      type: Number,
      required: true,
      min: 0,
      max: 5,
      default: 0
    }
  }
}, {
  timestamps: true
});

// Compound indexes for efficient queries
approvalRequestSchema.index({ astrologerId: 1, status: 1 });
approvalRequestSchema.index({ requestType: 1, status: 1 });
approvalRequestSchema.index({ status: 1, submittedAt: -1 });
approvalRequestSchema.index({ astrologerId: 1, requestType: 1, status: 1 });

// Virtual for formatted request type
approvalRequestSchema.virtual('requestTypeDisplay').get(function() {
  const typeMap = {
    'verification_badge': 'Verification Badge',
    'service_approval': 'Service Approval'
  };
  return typeMap[this.requestType] || this.requestType;
});

// Instance methods
approvalRequestSchema.methods.approve = function(reviewedBy, notes) {
  this.status = 'approved';
  this.reviewedAt = new Date();
  this.reviewedBy = reviewedBy || 'admin';
  if (notes) {
    this.notes = notes;
  }
  return this.save();
};

approvalRequestSchema.methods.reject = function(reviewedBy, reason) {
  this.status = 'rejected';
  this.reviewedAt = new Date();
  this.reviewedBy = reviewedBy || 'admin';
  if (reason) {
    this.rejectionReason = reason;
  }
  return this.save();
};

// Static methods
approvalRequestSchema.statics.getPendingRequests = function(filters = {}) {
  const query = { status: 'pending' };
  
  if (filters.requestType) {
    query.requestType = filters.requestType;
  }
  
  if (filters.astrologerId) {
    query.astrologerId = filters.astrologerId;
  }
  
  return this.find(query)
    .sort({ submittedAt: -1 })
    .populate('astrologerId', 'name email profilePicture')
    .populate('serviceId', 'name price category');
};

approvalRequestSchema.statics.getByAstrologer = function(astrologerId, requestType = null) {
  const query = { astrologerId };
  
  if (requestType) {
    query.requestType = requestType;
  }
  
  return this.find(query)
    .sort({ submittedAt: -1 })
    .populate('serviceId', 'name price category');
};

module.exports = mongoose.model('ApprovalRequest', approvalRequestSchema);

