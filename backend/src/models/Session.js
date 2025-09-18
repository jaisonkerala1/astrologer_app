const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true
  },
  clientId: {
    type: String,
    required: true,
    trim: true
  },
  clientName: {
    type: String,
    trim: true
  },
  clientPhone: {
    type: String,
    trim: true
  },
  duration: {
    type: Number,
    required: true,
    min: 0 // in minutes
  },
  earnings: {
    type: Number,
    required: true,
    min: 0
  },
  ratePerMinute: {
    type: Number,
    required: true,
    min: 0
  },
  type: {
    type: String,
    enum: ['call', 'message', 'video'],
    default: 'call'
  },
  status: {
    type: String,
    enum: ['pending', 'active', 'completed', 'cancelled'],
    default: 'pending'
  },
  startTime: {
    type: Date,
    default: Date.now
  },
  endTime: {
    type: Date
  },
  notes: {
    type: String,
    trim: true
  },
  rating: {
    type: Number,
    min: 1,
    max: 5
  },
  feedback: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Index for better query performance
sessionSchema.index({ astrologerId: 1 });
sessionSchema.index({ clientId: 1 });
sessionSchema.index({ status: 1 });
sessionSchema.index({ startTime: -1 });
sessionSchema.index({ createdAt: -1 });

// Virtual for session date
sessionSchema.virtual('sessionDate').get(function() {
  return this.startTime.toISOString().split('T')[0];
});

// Method to complete session
sessionSchema.methods.completeSession = function() {
  this.status = 'completed';
  this.endTime = new Date();
  return this.save();
};

// Method to cancel session
sessionSchema.methods.cancelSession = function() {
  this.status = 'cancelled';
  this.endTime = new Date();
  return this.save();
};

// Static method to get today's sessions for an astrologer
sessionSchema.statics.getTodaysSessions = function(astrologerId) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  return this.find({
    astrologerId,
    startTime: {
      $gte: today,
      $lt: tomorrow
    },
    status: 'completed'
  });
};

// Static method to get total earnings for an astrologer
sessionSchema.statics.getTotalEarnings = function(astrologerId) {
  return this.aggregate([
    { $match: { astrologerId: mongoose.Types.ObjectId(astrologerId), status: 'completed' } },
    { $group: { _id: null, totalEarnings: { $sum: '$earnings' } } }
  ]);
};

module.exports = mongoose.model('Session', sessionSchema);









