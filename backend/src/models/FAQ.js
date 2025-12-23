const mongoose = require('mongoose');

const faqSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    answer: {
      type: String,
      required: true,
      maxlength: 5000,
    },
    category: {
      type: String,
      required: true,
      enum: [
        'General',
        'Account & Profile',
        'Calendar & Availability',
        'Consultations',
        'Payments',
        'Live Streaming',
        'Technical',
        'Policies',
        'Other',
      ],
      index: true,
    },

    // Display order within category
    order: {
      type: Number,
      default: 0,
    },

    // Metrics
    helpfulCount: {
      type: Number,
      default: 0,
    },
    notHelpfulCount: {
      type: Number,
      default: 0,
    },
    viewCount: {
      type: Number,
      default: 0,
    },

    // Publishing
    isPublished: {
      type: Boolean,
      default: true,
    },

    // Author
    createdBy: {
      type: String, // Admin ID
    },
    createdByName: {
      type: String,
    },
    lastEditedBy: {
      type: String,
    },
    lastEditedByName: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
faqSchema.index({ category: 1, order: 1 });
faqSchema.index({ isPublished: 1, category: 1 });
faqSchema.index({ helpfulCount: -1 }); // For sorting by helpfulness

// Text search
faqSchema.index({ question: 'text', answer: 'text' });

module.exports = mongoose.model('FAQ', faqSchema);
