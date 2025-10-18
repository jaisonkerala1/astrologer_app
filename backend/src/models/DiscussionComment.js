const mongoose = require('mongoose');

const discussionCommentSchema = new mongoose.Schema({
  // Discussion reference
  discussionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Discussion',
    required: true,
    index: true
  },
  
  // Author information (can be astrologer or end-user)
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  authorType: {
    type: String,
    enum: ['astrologer', 'user'],
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true
  },
  authorPhoto: {
    type: String,
    default: null
  },
  
  // Content
  text: {
    type: String,
    required: true,
    trim: true,
    maxlength: [2000, 'Comment cannot exceed 2000 characters']
  },
  imageUrl: {
    type: String,
    default: null
  },
  
  // Nesting structure (1-level deep - Instagram style)
  parentCommentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DiscussionComment',
    default: null,
    index: true
  },
  
  // Engagement metrics
  likeCount: {
    type: Number,
    default: 0,
    min: 0
  },
  replyCount: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Status
  isDeleted: {
    type: Boolean,
    default: false,
    index: true
  },
  deletedAt: {
    type: Date,
    default: null
  },
  
  // Moderation
  isModerated: {
    type: Boolean,
    default: false
  },
  moderatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    default: null
  },
  moderatedAt: {
    type: Date,
    default: null
  },
  moderationReason: {
    type: String,
    default: null
  },
  
  // Edit tracking
  isEdited: {
    type: Boolean,
    default: false
  },
  editedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  collection: 'discussion_comments'
});

// Compound indexes for better query performance
discussionCommentSchema.index({ discussionId: 1, createdAt: -1 });
discussionCommentSchema.index({ discussionId: 1, parentCommentId: 1, createdAt: 1 });
discussionCommentSchema.index({ authorId: 1, authorType: 1 });
discussionCommentSchema.index({ parentCommentId: 1, isDeleted: 0 });

// Virtual to check if it's a top-level comment
discussionCommentSchema.virtual('isTopLevel').get(function() {
  return this.parentCommentId === null;
});

// Virtual to check if it's a reply
discussionCommentSchema.virtual('isReply').get(function() {
  return this.parentCommentId !== null;
});

// Method to soft delete comment
discussionCommentSchema.methods.softDelete = async function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.text = '[This comment has been deleted]';
  
  // Update parent discussion's comment count
  const Discussion = mongoose.model('Discussion');
  const discussion = await Discussion.findById(this.discussionId);
  if (discussion) {
    await discussion.updateEngagement();
  }
  
  // If this is a parent comment, update its reply count
  if (this.parentCommentId) {
    const parentComment = await mongoose.model('DiscussionComment').findById(this.parentCommentId);
    if (parentComment) {
      await parentComment.updateReplyCount();
    }
  }
  
  return this.save();
};

// Method to update reply count
discussionCommentSchema.methods.updateReplyCount = async function() {
  this.replyCount = await mongoose.model('DiscussionComment').countDocuments({
    parentCommentId: this._id,
    isDeleted: false
  });
  return this.save();
};

// Method to update like count
discussionCommentSchema.methods.updateLikeCount = async function() {
  const DiscussionLike = mongoose.model('DiscussionLike');
  this.likeCount = await DiscussionLike.countDocuments({
    targetId: this._id,
    targetType: 'comment'
  });
  return this.save();
};

// Pre-save hook to update discussion's last activity
discussionCommentSchema.pre('save', async function(next) {
  if (this.isNew && !this.isDeleted) {
    try {
      const Discussion = mongoose.model('Discussion');
      await Discussion.findByIdAndUpdate(
        this.discussionId,
        { 
          lastActivityAt: new Date(),
          $inc: { commentCount: 1 }
        }
      );
      
      // Update parent comment's reply count if this is a reply
      if (this.parentCommentId) {
        await mongoose.model('DiscussionComment').findByIdAndUpdate(
          this.parentCommentId,
          { $inc: { replyCount: 1 } }
        );
      }
    } catch (error) {
      console.error('Error updating discussion on comment save:', error);
    }
  }
  next();
});

// Ensure virtual fields are serialized
discussionCommentSchema.set('toJSON', { virtuals: true });
discussionCommentSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('DiscussionComment', discussionCommentSchema);

