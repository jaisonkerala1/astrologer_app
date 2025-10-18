const mongoose = require('mongoose');

const discussionLikeSchema = new mongoose.Schema({
  // Target reference (can be discussion or comment)
  targetId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  targetType: {
    type: String,
    enum: ['discussion', 'comment'],
    required: true,
    index: true
  },
  
  // User information (can be astrologer or end-user)
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  userType: {
    type: String,
    enum: ['astrologer', 'user'],
    required: true,
    index: true
  },
  userName: {
    type: String,
    required: true
  },
  userPhoto: {
    type: String,
    default: null
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  collection: 'discussion_likes'
});

// Compound indexes for better query performance
discussionLikeSchema.index({ targetId: 1, targetType: 1, userId: 1, userType: 1 }, { unique: true });
discussionLikeSchema.index({ userId: 1, userType: 1, createdAt: -1 });
discussionLikeSchema.index({ targetId: 1, targetType: 1, createdAt: -1 });

// Static method to toggle like
discussionLikeSchema.statics.toggleLike = async function(targetId, targetType, userId, userType, userName, userPhoto) {
  try {
    // Check if like already exists
    const existingLike = await this.findOne({
      targetId,
      targetType,
      userId,
      userType
    });
    
    if (existingLike) {
      // Unlike - remove the like
      // NOTE: The pre-remove hook will handle decrementing the count
      await existingLike.deleteOne();
      
      return { action: 'unliked', liked: false };
    } else {
      // Like - create new like
      const newLike = await this.create({
        targetId,
        targetType,
        userId,
        userType,
        userName,
        userPhoto
      });
      
      // Manually increment for new likes (no post-save hook for this)
      await updateTargetLikeCount(targetId, targetType, 1);
      
      return { action: 'liked', liked: true, like: newLike };
    }
  } catch (error) {
    console.error('Error toggling like:', error);
    throw error;
  }
};

// Static method to check if user has liked
discussionLikeSchema.statics.hasUserLiked = async function(targetId, targetType, userId, userType) {
  const like = await this.findOne({
    targetId,
    targetType,
    userId,
    userType
  });
  return !!like;
};

// Static method to get like count
discussionLikeSchema.statics.getLikeCount = async function(targetId, targetType) {
  return await this.countDocuments({
    targetId,
    targetType
  });
};

// Static method to get users who liked
discussionLikeSchema.statics.getUsersWhoLiked = async function(targetId, targetType, limit = 10) {
  return await this.find({
    targetId,
    targetType
  })
  .sort({ createdAt: -1 })
  .limit(limit)
  .select('userId userType userName userPhoto createdAt');
};

// Helper function to update like count on target
async function updateTargetLikeCount(targetId, targetType, increment) {
  if (targetType === 'discussion') {
    const Discussion = mongoose.model('Discussion');
    const discussion = await Discussion.findById(targetId);
    
    if (discussion) {
      // Ensure likeCount doesn't go below 0
      const newCount = Math.max(0, discussion.likeCount + increment);
      discussion.likeCount = newCount;
      discussion.lastActivityAt = new Date();
      discussion.calculateTrendingScore();
      await discussion.save();
    }
  } else if (targetType === 'comment') {
    const DiscussionComment = mongoose.model('DiscussionComment');
    const comment = await DiscussionComment.findById(targetId);
    
    if (comment) {
      // Ensure likeCount doesn't go below 0
      comment.likeCount = Math.max(0, comment.likeCount + increment);
      await comment.save();
    }
  }
}

// Pre-remove hook to update target like count
discussionLikeSchema.pre('deleteOne', { document: true, query: false }, async function(next) {
  try {
    await updateTargetLikeCount(this.targetId, this.targetType, -1);
  } catch (error) {
    console.error('Error in pre-remove hook:', error);
  }
  next();
});

module.exports = mongoose.model('DiscussionLike', discussionLikeSchema);

