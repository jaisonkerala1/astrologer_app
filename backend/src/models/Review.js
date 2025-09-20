const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  // Client who wrote the review
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Reference to User model (client app users)
    required: true
  },
  
  // Astrologer being reviewed
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer', // Reference to Astrologer model
    required: true
  },
  
  // Review details
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  
  reviewText: {
    type: String,
    required: true,
    maxlength: 1000
  },
  
  // Session/consultation this review is for
  sessionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Consultation',
    required: true
  },
  
  // Astrologer's reply
  astrologerReply: {
    type: String,
    maxlength: 500,
    default: null
  },
  
  repliedAt: {
    type: Date,
    default: null
  },
  
  // Visibility and status
  isPublic: {
    type: Boolean,
    default: true
  },
  
  isVerified: {
    type: Boolean,
    default: false // Set to true after consultation is completed
  },
  
  // Moderation
  isModerated: {
    type: Boolean,
    default: false
  },
  
  moderatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    default: null
  },
  
  moderatedAt: {
    type: Date,
    default: null
  },
  
  // Helpful for analytics
  helpfulCount: {
    type: Number,
    default: 0
  },
  
  // Source tracking
  source: {
    type: String,
    enum: ['app', 'web', 'import'],
    default: 'app'
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  collection: 'reviews'
});

// Indexes for better query performance
reviewSchema.index({ astrologerId: 1, createdAt: -1 });
reviewSchema.index({ clientId: 1 });
reviewSchema.index({ rating: 1 });
reviewSchema.index({ sessionId: 1 });
reviewSchema.index({ isPublic: 1, isVerified: 1 });

// Virtual for getting client name (populated)
reviewSchema.virtual('clientName').get(function() {
  return this.clientId?.name || 'Anonymous';
});

reviewSchema.virtual('clientAvatar').get(function() {
  return this.clientId?.profilePicture || '';
});

// Ensure virtual fields are serialized
reviewSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Review', reviewSchema);
