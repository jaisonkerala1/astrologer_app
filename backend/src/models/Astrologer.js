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
  bio: {
    type: String,
    maxlength: 1000,
    trim: true,
    default: ''
  },
  awards: {
    type: String,
    maxlength: 500,
    trim: true,
    default: ''
  },
  certificates: {
    type: String,
    maxlength: 500,
    trim: true,
    default: ''
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

module.exports = mongoose.model('Astrologer', astrologerSchema);
