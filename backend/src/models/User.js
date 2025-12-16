const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // Basic information
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  profilePicture: {
    type: String,
    default: null
  },
  
  // Account status
  isActive: {
    type: Boolean,
    default: true
  },
  isBanned: {
    type: Boolean,
    default: false
  },
  bannedAt: {
    type: Date,
    default: null
  },
  banReason: {
    type: String,
    default: null
  },
  
  // Statistics
  totalConsultations: {
    type: Number,
    default: 0
  },
  totalSpent: {
    type: Number,
    default: 0
  },
  
  // Activity tracking
  lastActiveAt: {
    type: Date,
    default: Date.now
  },
  
  // Preferences
  preferredLanguage: {
    type: String,
    default: 'en'
  },
  
  // Device info (for push notifications)
  fcmToken: {
    type: String,
    default: null
  },
  deviceInfo: {
    platform: String,
    appVersion: String
  }
}, {
  timestamps: true,
  collection: 'users'
});

// Indexes
userSchema.index({ email: 1 });
userSchema.index({ phone: 1 });
userSchema.index({ isActive: 1, isBanned: 1 });
userSchema.index({ createdAt: -1 });

// Instance methods
userSchema.methods.ban = function(reason) {
  this.isBanned = true;
  this.bannedAt = new Date();
  this.banReason = reason;
  return this.save();
};

userSchema.methods.unban = function() {
  this.isBanned = false;
  this.bannedAt = null;
  this.banReason = null;
  return this.save();
};

userSchema.methods.updateActivity = function() {
  this.lastActiveAt = new Date();
  return this.save();
};

userSchema.methods.incrementConsultations = function() {
  this.totalConsultations += 1;
  return this.save();
};

userSchema.methods.addSpending = function(amount) {
  this.totalSpent += amount;
  return this.save();
};

module.exports = mongoose.model('User', userSchema);
