const mongoose = require('mongoose');

/**
 * DiscussionComment Model
 * Represents comments and replies on discussions
 * Uses flat structure with parentCommentId for 1-level nesting
 * Supports real-time updates via Socket.IO
 */
const discussionCommentSchema = new mongoose.Schema({
  // Reference to parent discussion
  discussionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Discussion',
    required: true,
    index: true
  },

  // For replies: reference to parent comment (null for top-level comments)
  parentCommentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DiscussionComment',
    default: null,
    index: true
  },

  // Author reference
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true,
    trim: true
  },
  authorAvatar: {
    type: String,
    default: null
  },

  // Content
  content: {
    type: String,
    required: [true, 'Comment content is required'],
    trim: true,
    maxlength: [2000, 'Comment cannot exceed 2000 characters']
  },

  // Engagement
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer'
  }],
  likesCount: {
    type: Number,
    default: 0
  },
  repliesCount: {
    type: Number,
    default: 0
  },

  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  isEdited: {
    type: Boolean,
    default: false
  },
  editedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Compound indexes for efficient queries
discussionCommentSchema.index({ discussionId: 1, createdAt: -1 });
discussionCommentSchema.index({ discussionId: 1, parentCommentId: 1, createdAt: -1 });
discussionCommentSchema.index({ parentCommentId: 1, createdAt: 1 }); // For fetching replies

// Virtual for author's initial
discussionCommentSchema.virtual('authorInitial').get(function() {
  return this.authorName ? this.authorName.charAt(0).toUpperCase() : '?';
});

// Virtual to check if this is a reply
discussionCommentSchema.virtual('isReply').get(function() {
  return this.parentCommentId !== null;
});

// Method to toggle like
discussionCommentSchema.methods.toggleLike = async function(userId) {
  const userIdStr = userId.toString();
  const likeIndex = this.likes.findIndex(id => id.toString() === userIdStr);
  
  if (likeIndex > -1) {
    // Unlike
    this.likes.splice(likeIndex, 1);
    this.likesCount = Math.max(0, this.likesCount - 1);
  } else {
    // Like
    this.likes.push(userId);
    this.likesCount = this.likes.length;
  }
  
  await this.save();
  return likeIndex === -1; // Returns true if liked, false if unliked
};

// Method to check if user liked
discussionCommentSchema.methods.isLikedBy = function(userId) {
  if (!userId) return false;
  return this.likes.some(id => id.toString() === userId.toString());
};

// Method to increment reply count
discussionCommentSchema.methods.incrementReplyCount = async function() {
  this.repliesCount += 1;
  return this.save();
};

// Static method to get comments for a discussion with nested replies
discussionCommentSchema.statics.getCommentsWithReplies = async function(discussionId, userId = null, options = {}) {
  const { page = 1, limit = 50 } = options;
  const skip = (page - 1) * limit;

  // Get all comments for this discussion
  const allComments = await this.find({
    discussionId,
    isActive: true
  })
    .sort({ createdAt: 1 }) // Oldest first for proper threading
    .lean();

  // Separate parent comments and replies
  const parentComments = [];
  const repliesMap = new Map();

  allComments.forEach(comment => {
    // Add isLiked field
    comment.isLiked = userId ? comment.likes?.some(id => id.toString() === userId.toString()) : false;
    delete comment.likes; // Remove likes array, only send count

    if (comment.parentCommentId === null) {
      parentComments.push({ ...comment, replies: [] });
    } else {
      const parentId = comment.parentCommentId.toString();
      if (!repliesMap.has(parentId)) {
        repliesMap.set(parentId, []);
      }
      repliesMap.get(parentId).push(comment);
    }
  });

  // Attach replies to parent comments
  parentComments.forEach(parent => {
    const replies = repliesMap.get(parent._id.toString()) || [];
    parent.replies = replies.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    parent.repliesCount = replies.length;
  });

  // Sort parent comments by newest first and paginate
  const sortedParents = parentComments.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  const paginatedParents = sortedParents.slice(skip, skip + limit);

  return {
    comments: paginatedParents,
    pagination: {
      page,
      limit,
      total: parentComments.length,
      pages: Math.ceil(parentComments.length / limit),
      hasMore: page * limit < parentComments.length
    }
  };
};

// Static method to get flat list of comments (for API flexibility)
discussionCommentSchema.statics.getFlat = async function(discussionId, userId = null, options = {}) {
  const { page = 1, limit = 100 } = options;
  const skip = (page - 1) * limit;

  const [comments, total] = await Promise.all([
    this.find({ discussionId, isActive: true })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    this.countDocuments({ discussionId, isActive: true })
  ]);

  // Add isLiked field
  const commentsWithLiked = comments.map(c => ({
    ...c,
    isLiked: userId ? c.likes?.some(id => id.toString() === userId.toString()) : false,
    likes: undefined
  }));

  return {
    comments: commentsWithLiked,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
      hasMore: page * limit < total
    }
  };
};

// Ensure virtuals are included in JSON
discussionCommentSchema.set('toJSON', { virtuals: true });
discussionCommentSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('DiscussionComment', discussionCommentSchema);

