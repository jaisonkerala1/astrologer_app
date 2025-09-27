const mongoose = require('mongoose');

const consultationSchema = new mongoose.Schema({
  // Basic consultation information
  clientName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  clientPhone: {
    type: String,
    required: true,
    trim: true,
    maxlength: 15
  },
  clientEmail: {
    type: String,
    trim: true,
    lowercase: true,
    maxlength: 100
  },
  
  // Scheduling information
  scheduledTime: {
    type: Date,
    required: true
  },
  duration: {
    type: Number,
    required: true,
    min: 15,
    max: 180, // Maximum 3 hours
    default: 30 // Default 30 minutes
  },
  
  // Financial information
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'INR',
    enum: ['INR', 'USD', 'EUR']
  },
  
  // Consultation details
  type: {
    type: String,
    required: true,
    enum: ['phone', 'video', 'inPerson', 'chat'],
    default: 'phone'
  },
  status: {
    type: String,
    required: true,
    enum: ['scheduled', 'inProgress', 'completed', 'cancelled', 'noShow'],
    default: 'scheduled'
  },
  
  // Astrologer reference
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true
  },
  
  // Consultation content
  notes: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  consultationTopics: [{
    type: String,
    trim: true,
    maxlength: 50
  }],
  
  // Timestamps
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
    enum: ['astrologer', 'client', 'system']
  },
  cancellationReason: {
    type: String,
    trim: true,
    maxlength: 200
  },
  
  // Rating and feedback (from clients - will be implemented later)
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
  
  // Astrologer rating fields (separate from client rating)
  astrologerRating: {
    type: Number,
    min: 1,
    max: 5
  },
  astrologerFeedback: {
    type: String,
    trim: true,
    maxlength: 500
  },
  astrologerRatedAt: {
    type: Date
  },
  
  // Share tracking fields
  shareCount: {
    type: Number,
    default: 0,
    min: 0
  },
  lastSharedAt: {
    type: Date
  },
  
  // Reschedule tracking fields
  rescheduleCount: {
    type: Number,
    default: 0,
    min: 0
  },
  lastRescheduledAt: {
    type: Date
  },
  originalScheduledTime: {
    type: Date
  },
  
  // Status history tracking
  statusHistory: [{
    status: {
      type: String,
      enum: ['scheduled', 'inProgress', 'completed', 'cancelled', 'noShow', 'rescheduled'],
      required: true
    },
    timestamp: {
      type: Date,
      default: Date.now
    },
    notes: {
      type: String,
      trim: true
    },
    scheduledTime: {
      type: Date
    }
  }],
  
  // Reminder settings
  reminderSent: {
    type: Boolean,
    default: false
  },
  reminderSentAt: {
    type: Date
  },
  
  // Manual consultation flag
  isManual: {
    type: Boolean,
    default: true // All consultations added through the app are manual
  },
  
  // Metadata
  source: {
    type: String,
    enum: ['app', 'website', 'admin'],
    default: 'app'
  },
  
  // Additional client information
  clientAge: {
    type: Number,
    min: 18,
    max: 100
  },
  clientGender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say']
  },
  preferredLanguage: {
    type: String,
    default: 'en',
    maxlength: 10
  }
}, {
  timestamps: true // This adds createdAt and updatedAt automatically
});

// Indexes for better query performance
consultationSchema.index({ astrologerId: 1, scheduledTime: -1 });
consultationSchema.index({ clientPhone: 1 });
consultationSchema.index({ status: 1 });
consultationSchema.index({ scheduledTime: 1 });
consultationSchema.index({ isManual: 1 });
consultationSchema.index({ createdAt: -1 });

// Compound indexes for common queries
consultationSchema.index({ astrologerId: 1, status: 1 });
consultationSchema.index({ astrologerId: 1, scheduledTime: 1, status: 1 });

// Virtual for consultation duration in hours
consultationSchema.virtual('durationInHours').get(function() {
  return this.duration / 60;
});

// Virtual for time until consultation
consultationSchema.virtual('timeUntilConsultation').get(function() {
  const now = new Date();
  const timeDiff = this.scheduledTime.getTime() - now.getTime();
  return timeDiff;
});

// Virtual for consultation status display
consultationSchema.virtual('statusDisplay').get(function() {
  const statusMap = {
    'scheduled': 'Scheduled',
    'inProgress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'noShow': 'No Show'
  };
  return statusMap[this.status] || this.status;
});

// Instance methods
consultationSchema.methods.updateStatus = function(newStatus, additionalData = {}) {
  this.status = newStatus;
  
  if (newStatus === 'inProgress') {
    this.startedAt = new Date();
  } else if (newStatus === 'completed') {
    this.completedAt = new Date();
  } else if (newStatus === 'cancelled') {
    this.cancelledAt = new Date();
    this.cancelledBy = additionalData.cancelledBy || 'astrologer';
    this.cancellationReason = additionalData.cancellationReason || '';
  }
  
  return this.save();
};

consultationSchema.methods.addNotes = function(notes) {
  this.notes = notes;
  return this.save();
};

consultationSchema.methods.addRating = function(rating, feedback = '') {
  this.rating = rating;
  this.feedback = feedback;
  return this.save();
};

consultationSchema.methods.sendReminder = function() {
  this.reminderSent = true;
  this.reminderSentAt = new Date();
  return this.save();
};

// Static methods
consultationSchema.statics.getUpcomingConsultations = function(astrologerId, limit = 10) {
  const now = new Date();
  return this.find({
    astrologerId,
    scheduledTime: { $gte: now },
    status: { $in: ['scheduled', 'inProgress'] }
  })
  .sort({ scheduledTime: 1 })
  .limit(limit);
};

consultationSchema.statics.getTodaysConsultations = function(astrologerId) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  return this.find({
    astrologerId,
    scheduledTime: {
      $gte: today,
      $lt: tomorrow
    }
  }).sort({ scheduledTime: 1 });
};

consultationSchema.statics.getCompletedConsultations = function(astrologerId, limit = 50) {
  return this.find({
    astrologerId,
    status: 'completed'
  })
  .sort({ completedAt: -1 })
  .limit(limit);
};

consultationSchema.statics.getTotalEarnings = function(astrologerId, startDate, endDate) {
  const matchCriteria = {
    astrologerId: mongoose.Types.ObjectId(astrologerId),
    status: 'completed'
  };
  
  if (startDate && endDate) {
    matchCriteria.completedAt = {
      $gte: startDate,
      $lte: endDate
    };
  }
  
  return this.aggregate([
    { $match: matchCriteria },
    { $group: { _id: null, totalEarnings: { $sum: '$amount' } } }
  ]);
};

consultationSchema.statics.getConsultationStats = function(astrologerId) {
  return this.aggregate([
    { $match: { astrologerId: mongoose.Types.ObjectId(astrologerId) } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalAmount: { $sum: '$amount' }
      }
    }
  ]);
};

// Pre-save middleware to validate scheduling
consultationSchema.pre('save', function(next) {
  // Ensure scheduled time is in the future for new consultations
  if (this.isNew && this.scheduledTime <= new Date()) {
    return next(new Error('Scheduled time must be in the future'));
  }
  
  // Auto-calculate amount if not provided (using astrologer's rate)
  if (!this.amount && this.duration) {
    // This would need to be populated from astrologer data
    // For now, we'll use a default rate
    this.amount = this.duration * 10; // ₹10 per minute default
  }
  
  next();
});

// Pre-update middleware to handle status changes
consultationSchema.pre('findOneAndUpdate', function(next) {
  const update = this.getUpdate();
  
  if (update.status === 'inProgress' && !update.startedAt) {
    update.startedAt = new Date();
  }
  
  if (update.status === 'completed' && !update.completedAt) {
    update.completedAt = new Date();
  }
  
  if (update.status === 'cancelled' && !update.cancelledAt) {
    update.cancelledAt = new Date();
  }
  
  next();
});

module.exports = mongoose.model('Consultation', consultationSchema);
