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
  activeSession: {
    sessionId: {
      type: String,
      default: null
    },
    deviceInfo: {
      userAgent: {
        type: String,
        default: null
      },
      platform: {
        type: String,
        default: null
      },
      ipAddress: {
        type: String,
        default: null
      }
    },
    createdAt: {
      type: Date,
      default: null
    },
    lastSeenAt: {
      type: Date,
      default: null
    }
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  // Professional profile fields with UX-optimized validation
  bio: {
    type: String,
    maxlength: [1000, 'Bio cannot exceed 1000 characters'],
    trim: true,
    default: '',
    validate: {
      validator: function(v) {
        // Allow empty string but validate length if provided
        return v.length <= 1000;
      },
      message: 'Bio must be 1000 characters or less'
    }
  },
  awards: {
    type: String,
    maxlength: [500, 'Awards description cannot exceed 500 characters'],
    trim: true,
    default: '',
    validate: {
      validator: function(v) {
        return v.length <= 500;
      },
      message: 'Awards description must be 500 characters or less'
    }
  },
  certificates: {
    type: String,
    maxlength: [500, 'Certificates description cannot exceed 500 characters'],
    trim: true,
    default: '',
    validate: {
      validator: function(v) {
        return v.length <= 500;
      },
      message: 'Certificates description must be 500 characters or less'
    }
  }
}, {
  timestamps: true
});

// Index for better query performance
astrologerSchema.index({ phone: 1 });
astrologerSchema.index({ email: 1 });
astrologerSchema.index({ isOnline: 1 });
astrologerSchema.index({ isActive: 1 });
astrologerSchema.index({ 'activeSession.sessionId': 1 });

// Virtual for formatted phone number
astrologerSchema.virtual('formattedPhone').get(function() {
  return this.phone.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
});

// Method to update last seen
astrologerSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  if (this.activeSession) {
    this.activeSession.lastSeenAt = new Date();
  }
  return this.save();
};

// Method to toggle online status
astrologerSchema.methods.toggleOnlineStatus = function() {
  this.isOnline = !this.isOnline;
  this.lastSeen = new Date();
  if (this.activeSession) {
    this.activeSession.lastSeenAt = new Date();
  }
  return this.save();
};

// Method to add earnings
astrologerSchema.methods.addEarnings = function(amount) {
  this.totalEarnings += amount;
  return this.save();
};

module.exports = mongoose.model('Astrologer', astrologerSchema);
