const mongoose = require('mongoose');

const astrologerSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  profilePicture: {
    type: String,
    default: null
  },
  specializations: [{
    type: String,
    trim: true
  }],
  languages: [{
    type: String,
    trim: true
  }],
  experience: {
    type: Number,
    required: true,
    min: 0
  },
  ratePerMinute: {
    type: Number,
    required: true,
    min: 0
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  totalEarnings: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  // Response Time Tracking
  responseTimeStats: {
    averageResponseTime: {
      type: Number,
      default: 0, // in minutes
      min: 0
    },
    totalResponses: {
      type: Number,
      default: 0
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    },
    responseTimeHistory: [{
      consultationId: {
        type: String,
        required: true
      },
      responseTime: {
        type: Number,
        required: true // in minutes
      },
      consultationType: {
        type: String,
        enum: ['call', 'video', 'chat', 'in_person'],
        required: true
      },
      timestamp: {
        type: Date,
        default: Date.now
      }
    }]
  }
}, {
  timestamps: true
});

// Index for better query performance
astrologerSchema.index({ phone: 1 });
astrologerSchema.index({ email: 1 });
astrologerSchema.index({ isOnline: 1 });
astrologerSchema.index({ isActive: 1 });

// Virtual for formatted phone number
astrologerSchema.virtual('formattedPhone').get(function() {
  return this.phone.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
});

// Method to update last seen
astrologerSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  return this.save();
};

// Method to toggle online status
astrologerSchema.methods.toggleOnlineStatus = function() {
  this.isOnline = !this.isOnline;
  this.lastSeen = new Date();
  return this.save();
};

// Method to add earnings
astrologerSchema.methods.addEarnings = function(amount) {
  this.totalEarnings += amount;
  return this.save();
};

// Method to update response time
astrologerSchema.methods.updateResponseTime = function(consultationId, responseTime, consultationType) {
  // Add new response time to history
  this.responseTimeStats.responseTimeHistory.push({
    consultationId,
    responseTime,
    consultationType,
    timestamp: new Date()
  });
  
  // Update total responses count
  this.responseTimeStats.totalResponses += 1;
  
  // Calculate new average response time
  const totalTime = this.responseTimeStats.responseTimeHistory.reduce((sum, entry) => sum + entry.responseTime, 0);
  this.responseTimeStats.averageResponseTime = totalTime / this.responseTimeStats.totalResponses;
  
  // Update last updated timestamp
  this.responseTimeStats.lastUpdated = new Date();
  
  return this.save();
};

// Method to get response time statistics
astrologerSchema.methods.getResponseTimeStats = function() {
  const stats = this.responseTimeStats;
  const history = stats.responseTimeHistory;
  
  // Calculate additional statistics
  const responseTimes = history.map(entry => entry.responseTime);
  const minResponseTime = responseTimes.length > 0 ? Math.min(...responseTimes) : 0;
  const maxResponseTime = responseTimes.length > 0 ? Math.max(...responseTimes) : 0;
  
  // Calculate response time by consultation type
  const byType = {};
  history.forEach(entry => {
    if (!byType[entry.consultationType]) {
      byType[entry.consultationType] = { count: 0, totalTime: 0, avgTime: 0 };
    }
    byType[entry.consultationType].count += 1;
    byType[entry.consultationType].totalTime += entry.responseTime;
    byType[entry.consultationType].avgTime = byType[entry.consultationType].totalTime / byType[entry.consultationType].count;
  });
  
  return {
    averageResponseTime: stats.averageResponseTime,
    totalResponses: stats.totalResponses,
    minResponseTime,
    maxResponseTime,
    lastUpdated: stats.lastUpdated,
    byConsultationType: byType,
    recentHistory: history.slice(-10) // Last 10 responses
  };
};

module.exports = mongoose.model('Astrologer', astrologerSchema);
