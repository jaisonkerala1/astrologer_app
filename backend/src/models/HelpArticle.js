const mongoose = require('mongoose');

const helpArticleSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 300,
    },
    content: {
      type: String,
      required: true,
      maxlength: 50000, // Rich text content
    },
    category: {
      type: String,
      required: true,
      enum: [
        'Getting Started',
        'Account Management',
        'Calendar & Scheduling',
        'Consultations',
        'Payments & Earnings',
        'Live Streaming',
        'Technical Issues',
        'Best Practices',
        'Other',
      ],
      index: true,
    },
    tags: [
      {
        type: String,
        trim: true,
      },
    ],

    // SEO
    slug: {
      type: String,
      unique: true,
      required: true,
      trim: true,
      lowercase: true,
    },
    metaDescription: {
      type: String,
      maxlength: 200,
    },

    // Publishing
    status: {
      type: String,
      enum: ['draft', 'published', 'archived'],
      default: 'draft',
      index: true,
    },
    publishedAt: {
      type: Date,
    },

    // Metrics
    viewCount: {
      type: Number,
      default: 0,
    },
    isPopular: {
      type: Boolean,
      default: false,
    },
    helpfulCount: {
      type: Number,
      default: 0,
    },
    notHelpfulCount: {
      type: Number,
      default: 0,
    },

    // Author (admin)
    authorId: {
      type: String, // Admin ID
    },
    authorName: {
      type: String,
    },

    // Last updated by
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
helpArticleSchema.index({ status: 1, publishedAt: -1 });
helpArticleSchema.index({ category: 1, status: 1 });
helpArticleSchema.index({ tags: 1 });
helpArticleSchema.index({ slug: 1 });
helpArticleSchema.index({ viewCount: -1 }); // For popular articles

// Text search index
helpArticleSchema.index({ title: 'text', content: 'text', tags: 'text' });

// Generate slug from title if not provided
helpArticleSchema.pre('save', function (next) {
  if (this.isModified('title') && !this.slug) {
    this.slug = this.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }
  
  // Auto-publish if status changes to published
  if (this.isModified('status') && this.status === 'published' && !this.publishedAt) {
    this.publishedAt = new Date();
  }
  
  next();
});

module.exports = mongoose.model('HelpArticle', helpArticleSchema);
