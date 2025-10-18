const Discussion = require('../models/Discussion');
const DiscussionComment = require('../models/DiscussionComment');
const DiscussionLike = require('../models/DiscussionLike');
const SavedPost = require('../models/SavedPost');
const NotificationSubscription = require('../models/NotificationSubscription');
const Astrologer = require('../models/Astrologer');

// ============================================
// DISCUSSION CRUD OPERATIONS
// ============================================

/**
 * Create new discussion
 * POST /api/discussions
 */
exports.createDiscussion = async (req, res) => {
  try {
    const { title, content, imageUrl, tags, category, visibleTo } = req.body;
    const astrologerId = req.user.id; // From auth middleware

    // Get astrologer details
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Create discussion
    const discussion = await Discussion.create({
      authorId: astrologerId,
      authorName: astrologer.name,
      authorPhoto: astrologer.profilePicture,
      title,
      content,
      imageUrl: imageUrl || null,
      tags: tags || [],
      category: category || 'general',
      visibleTo: visibleTo || 'both',
      isPublic: true
    });

    // Auto-subscribe author to notifications
    await NotificationSubscription.autoSubscribeAuthor(
      discussion._id,
      astrologerId,
      'astrologer'
    );

    // Emit real-time event
    if (req.io) {
      req.io.emit('discussion:created', {
        discussion: discussion.toJSON(),
        author: {
          id: astrologer._id,
          name: astrologer.name,
          photo: astrologer.profilePicture
        }
      });
    }

    res.status(201).json({
      success: true,
      message: 'Discussion created successfully',
      data: discussion
    });
  } catch (error) {
    console.error('Error creating discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create discussion',
      error: error.message
    });
  }
};

/**
 * Get all discussions with pagination and filters
 * GET /api/discussions
 */
exports.getDiscussions = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      category,
      tags,
      authorId,
      visibleTo,
      search
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    const query = {
      isDeleted: false,
      isPublic: true
    };

    if (category) query.category = category;
    if (authorId) query.authorId = authorId;
    if (visibleTo) query.visibleTo = visibleTo;
    if (tags) {
      const tagsArray = tags.split(',').map(tag => tag.trim());
      query.tags = { $in: tagsArray };
    }
    if (search) {
      query.$text = { $search: search };
    }

    // Execute query
    const discussions = await Discussion.find(query)
      .sort({ [sortBy]: sortOrder === 'desc' ? -1 : 1 })
      .limit(parseInt(limit))
      .skip(skip)
      .lean();

    const total = await Discussion.countDocuments(query);

    // Check if current user has liked/saved each discussion
    if (req.user) {
      for (let discussion of discussions) {
        discussion.isLiked = await DiscussionLike.hasUserLiked(
          discussion._id,
          'discussion',
          req.user.id,
          req.user.userType || 'astrologer'
        );
        discussion.isSaved = await SavedPost.hasUserSaved(
          discussion._id,
          req.user.id,
          req.user.userType || 'astrologer'
        );
        discussion.isSubscribed = await NotificationSubscription.isUserSubscribed(
          discussion._id,
          req.user.id,
          req.user.userType || 'astrologer'
        );
      }
    }

    res.status(200).json({
      success: true,
      data: discussions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch discussions',
      error: error.message
    });
  }
};

/**
 * Get single discussion by ID
 * GET /api/discussions/:id
 */
exports.getDiscussionById = async (req, res) => {
  try {
    const { id } = req.params;

    const discussion = await Discussion.findOne({
      _id: id,
      isDeleted: false
    }).lean();

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Increment view count
    await Discussion.findByIdAndUpdate(id, {
      $inc: { viewCount: 1 },
      lastActivityAt: new Date()
    });

    // Check if current user has liked/saved
    if (req.user) {
      discussion.isLiked = await DiscussionLike.hasUserLiked(
        discussion._id,
        'discussion',
        req.user.id,
        req.user.userType || 'astrologer'
      );
      discussion.isSaved = await SavedPost.hasUserSaved(
        discussion._id,
        req.user.id,
        req.user.userType || 'astrologer'
      );
      discussion.isSubscribed = await NotificationSubscription.isUserSubscribed(
        discussion._id,
        req.user.id,
        req.user.userType || 'astrologer'
      );
    }

    res.status(200).json({
      success: true,
      data: discussion
    });
  } catch (error) {
    console.error('Error fetching discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch discussion',
      error: error.message
    });
  }
};

/**
 * Update discussion
 * PUT /api/discussions/:id
 */
exports.updateDiscussion = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, imageUrl, tags, category, visibleTo } = req.body;
    const userId = req.user.id;

    const discussion = await Discussion.findOne({ _id: id, isDeleted: false });

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Check ownership
    if (discussion.authorId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to update this discussion'
      });
    }

    // Update fields
    if (title) discussion.title = title;
    if (content) discussion.content = content;
    if (imageUrl !== undefined) discussion.imageUrl = imageUrl;
    if (tags) discussion.tags = tags;
    if (category) discussion.category = category;
    if (visibleTo) discussion.visibleTo = visibleTo;

    await discussion.save();

    // Emit real-time event
    if (req.io) {
      req.io.emit('discussion:updated', {
        discussionId: discussion._id,
        discussion: discussion.toJSON()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Discussion updated successfully',
      data: discussion
    });
  } catch (error) {
    console.error('Error updating discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update discussion',
      error: error.message
    });
  }
};

/**
 * Delete discussion (soft delete)
 * DELETE /api/discussions/:id
 */
exports.deleteDiscussion = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const discussion = await Discussion.findOne({ _id: id, isDeleted: false });

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Check ownership
    if (discussion.authorId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this discussion'
      });
    }

    await discussion.softDelete();

    // Emit real-time event
    if (req.io) {
      req.io.emit('discussion:deleted', {
        discussionId: discussion._id
      });
    }

    res.status(200).json({
      success: true,
      message: 'Discussion deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete discussion',
      error: error.message
    });
  }
};

/**
 * Get current user's discussions
 * GET /api/discussions/my-posts
 */
exports.getMyDiscussions = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const discussions = await Discussion.find({
      authorId: userId,
      isDeleted: false
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(skip)
      .lean();

    const total = await Discussion.countDocuments({
      authorId: userId,
      isDeleted: false
    });

    res.status(200).json({
      success: true,
      data: discussions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching user discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch your discussions',
      error: error.message
    });
  }
};

// ============================================
// ENGAGEMENT: LIKES
// ============================================

/**
 * Toggle like on discussion
 * POST /api/discussions/:id/like
 */
exports.toggleLike = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';

    // Get user details
    let userName, userPhoto;
    if (userType === 'astrologer') {
      const astrologer = await Astrologer.findById(userId);
      userName = astrologer.name;
      userPhoto = astrologer.profilePicture;
    } else {
      // For end-users (to be implemented when user model is ready)
      userName = req.user.name;
      userPhoto = req.user.profilePicture;
    }

    const result = await DiscussionLike.toggleLike(
      id,
      'discussion',
      userId,
      userType,
      userName,
      userPhoto
    );

    // Get updated like count
    const discussion = await Discussion.findById(id).select('likeCount');

    // Emit real-time event
    if (req.io) {
      req.io.emit('discussion:like', {
        discussionId: id,
        action: result.action,
        likeCount: discussion.likeCount,
        user: { id: userId, name: userName, photo: userPhoto }
      });
    }

    res.status(200).json({
      success: true,
      message: result.action === 'liked' ? 'Discussion liked' : 'Discussion unliked',
      data: {
        liked: result.liked,
        likeCount: discussion.likeCount
      }
    });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle like',
      error: error.message
    });
  }
};

/**
 * Get users who liked discussion
 * GET /api/discussions/:id/likes
 */
exports.getDiscussionLikes = async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50 } = req.query;

    const likes = await DiscussionLike.getUsersWhoLiked(
      id,
      'discussion',
      parseInt(limit)
    );

    const likeCount = await DiscussionLike.getLikeCount(id, 'discussion');

    res.status(200).json({
      success: true,
      data: {
        likes,
        count: likeCount
      }
    });
  } catch (error) {
    console.error('Error fetching likes:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch likes',
      error: error.message
    });
  }
};

/**
 * Increment view count
 * POST /api/discussions/:id/view
 */
exports.incrementView = async (req, res) => {
  try {
    const { id } = req.params;

    const discussion = await Discussion.findById(id);
    if (discussion) {
      await discussion.incrementView();
    }

    res.status(200).json({
      success: true,
      message: 'View recorded'
    });
  } catch (error) {
    console.error('Error incrementing view:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record view',
      error: error.message
    });
  }
};

/**
 * Increment share count
 * POST /api/discussions/:id/share
 */
exports.incrementShare = async (req, res) => {
  try {
    const { id } = req.params;

    const discussion = await Discussion.findById(id);
    if (discussion) {
      await discussion.incrementShare();

      // Emit real-time event
      if (req.io) {
        req.io.emit('discussion:share', {
          discussionId: id,
          shareCount: discussion.shareCount
        });
      }
    }

    res.status(200).json({
      success: true,
      message: 'Share recorded',
      data: {
        shareCount: discussion.shareCount
      }
    });
  } catch (error) {
    console.error('Error incrementing share:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record share',
      error: error.message
    });
  }
};

// ============================================
// COMMENTS
// ============================================

/**
 * Add comment to discussion
 * POST /api/discussions/:id/comments
 */
exports.addComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { text, imageUrl, parentCommentId } = req.body;
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';

    // Get user details
    let userName, userPhoto;
    if (userType === 'astrologer') {
      const astrologer = await Astrologer.findById(userId);
      userName = astrologer.name;
      userPhoto = astrologer.profilePicture;
    } else {
      userName = req.user.name;
      userPhoto = req.user.profilePicture;
    }

    // Validate parent comment if provided (1-level nesting)
    let finalParentCommentId = parentCommentId || null;
    if (parentCommentId) {
      const parentComment = await DiscussionComment.findById(parentCommentId);
      if (!parentComment) {
        return res.status(404).json({
          success: false,
          message: 'Parent comment not found'
        });
      }
      // If replying to a reply, link to the top-level parent instead
      if (parentComment.parentCommentId) {
        finalParentCommentId = parentComment.parentCommentId;
      }
    }

    // Create comment
    const comment = await DiscussionComment.create({
      discussionId: id,
      authorId: userId,
      authorType: userType,
      authorName: userName,
      authorPhoto: userPhoto,
      text,
      imageUrl: imageUrl || null,
      parentCommentId: finalParentCommentId
    });

    // Emit real-time event
    if (req.io) {
      req.io.to(`discussion:${id}`).emit('comment:added', {
        discussionId: id,
        comment: comment.toJSON(),
        author: { id: userId, name: userName, photo: userPhoto }
      });
    }

    // Send notifications to subscribers
    await sendCommentNotifications(id, comment, userId, userType);

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: comment
    });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add comment',
      error: error.message
    });
  }
};

/**
 * Get comments for discussion
 * GET /api/discussions/:id/comments
 */
exports.getComments = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 50, structure = 'flat' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get all top-level comments
    const comments = await DiscussionComment.find({
      discussionId: id,
      parentCommentId: null,
      isDeleted: false
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(skip)
      .lean();

    // If nested structure requested, get replies for each comment
    if (structure === 'nested') {
      for (let comment of comments) {
        const replies = await DiscussionComment.find({
          parentCommentId: comment._id,
          isDeleted: false
        })
          .sort({ createdAt: 1 })
          .lean();

        // Check if user has liked each reply
        if (req.user) {
          for (let reply of replies) {
            reply.isLiked = await DiscussionLike.hasUserLiked(
              reply._id,
              'comment',
              req.user.id,
              req.user.userType || 'astrologer'
            );
          }
        }

        comment.replies = replies;

        // Check if user has liked the comment
        if (req.user) {
          comment.isLiked = await DiscussionLike.hasUserLiked(
            comment._id,
            'comment',
            req.user.id,
            req.user.userType || 'astrologer'
          );
        }
      }
    } else {
      // Flat structure - check likes for all comments
      if (req.user) {
        for (let comment of comments) {
          comment.isLiked = await DiscussionLike.hasUserLiked(
            comment._id,
            'comment',
            req.user.id,
            req.user.userType || 'astrologer'
          );
        }
      }
    }

    const total = await DiscussionComment.countDocuments({
      discussionId: id,
      parentCommentId: null,
      isDeleted: false
    });

    res.status(200).json({
      success: true,
      data: comments,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch comments',
      error: error.message
    });
  }
};

/**
 * Update comment
 * PUT /api/comments/:commentId
 */
exports.updateComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const { text, imageUrl } = req.body;
    const userId = req.user.id;

    const comment = await DiscussionComment.findOne({
      _id: commentId,
      isDeleted: false
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Check ownership
    if (comment.authorId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to update this comment'
      });
    }

    // Update fields
    if (text) comment.text = text;
    if (imageUrl !== undefined) comment.imageUrl = imageUrl;
    comment.isEdited = true;
    comment.editedAt = new Date();

    await comment.save();

    // Emit real-time event
    if (req.io) {
      req.io.to(`discussion:${comment.discussionId}`).emit('comment:updated', {
        commentId: comment._id,
        comment: comment.toJSON()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Comment updated successfully',
      data: comment
    });
  } catch (error) {
    console.error('Error updating comment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update comment',
      error: error.message
    });
  }
};

/**
 * Delete comment (soft delete)
 * DELETE /api/comments/:commentId
 */
exports.deleteComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user.id;

    const comment = await DiscussionComment.findOne({
      _id: commentId,
      isDeleted: false
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Check ownership or discussion ownership
    const discussion = await Discussion.findById(comment.discussionId);
    const isOwner = comment.authorId.toString() === userId;
    const isDiscussionAuthor = discussion && discussion.authorId.toString() === userId;

    if (!isOwner && !isDiscussionAuthor) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this comment'
      });
    }

    await comment.softDelete();

    // Emit real-time event
    if (req.io) {
      req.io.to(`discussion:${comment.discussionId}`).emit('comment:deleted', {
        commentId: comment._id,
        discussionId: comment.discussionId
      });
    }

    res.status(200).json({
      success: true,
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete comment',
      error: error.message
    });
  }
};

/**
 * Toggle like on comment
 * POST /api/comments/:commentId/like
 */
exports.toggleCommentLike = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';

    // Get user details
    let userName, userPhoto;
    if (userType === 'astrologer') {
      const astrologer = await Astrologer.findById(userId);
      userName = astrologer.name;
      userPhoto = astrologer.profilePicture;
    } else {
      userName = req.user.name;
      userPhoto = req.user.profilePicture;
    }

    const result = await DiscussionLike.toggleLike(
      commentId,
      'comment',
      userId,
      userType,
      userName,
      userPhoto
    );

    // Get updated like count and discussion ID
    const comment = await DiscussionComment.findById(commentId).select('likeCount discussionId');

    // Emit real-time event
    if (req.io) {
      req.io.to(`discussion:${comment.discussionId}`).emit('comment:like', {
        commentId,
        action: result.action,
        likeCount: comment.likeCount,
        user: { id: userId, name: userName, photo: userPhoto }
      });
    }

    res.status(200).json({
      success: true,
      message: result.action === 'liked' ? 'Comment liked' : 'Comment unliked',
      data: {
        liked: result.liked,
        likeCount: comment.likeCount
      }
    });
  } catch (error) {
    console.error('Error toggling comment like:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle comment like',
      error: error.message
    });
  }
};

/**
 * Get users who liked comment
 * GET /api/comments/:commentId/likes
 */
exports.getCommentLikes = async (req, res) => {
  try {
    const { commentId } = req.params;
    const { limit = 50 } = req.query;

    const likes = await DiscussionLike.getUsersWhoLiked(
      commentId,
      'comment',
      parseInt(limit)
    );

    const likeCount = await DiscussionLike.getLikeCount(commentId, 'comment');

    res.status(200).json({
      success: true,
      data: {
        likes,
        count: likeCount
      }
    });
  } catch (error) {
    console.error('Error fetching comment likes:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch comment likes',
      error: error.message
    });
  }
};

// ============================================
// SAVED POSTS
// ============================================

/**
 * Toggle save on discussion
 * POST /api/discussions/:id/save
 */
exports.toggleSave = async (req, res) => {
  try {
    const { id } = req.params;
    const { collection } = req.body;
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';

    const result = await SavedPost.toggleSave(
      id,
      userId,
      userType,
      collection || 'default'
    );

    // Get updated save count
    const discussion = await Discussion.findById(id).select('saveCount');

    res.status(200).json({
      success: true,
      message: result.action === 'saved' ? 'Discussion saved' : 'Discussion unsaved',
      data: {
        saved: result.saved,
        saveCount: discussion.saveCount
      }
    });
  } catch (error) {
    console.error('Error toggling save:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle save',
      error: error.message
    });
  }
};

/**
 * Get user's saved posts
 * GET /api/discussions/saved
 */
exports.getSavedPosts = async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';
    const { page = 1, limit = 20, collection } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const savedPosts = await SavedPost.getUserSavedPosts(userId, userType, {
      collection,
      limit: parseInt(limit),
      skip,
      sortBy: 'savedAt',
      sortOrder: -1
    });

    const total = await SavedPost.countDocuments({
      userId,
      userType,
      ...(collection && { collection })
    });

    res.status(200).json({
      success: true,
      data: savedPosts,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching saved posts:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch saved posts',
      error: error.message
    });
  }
};

// ============================================
// NOTIFICATION SUBSCRIPTIONS
// ============================================

/**
 * Toggle notification subscription
 * POST /api/discussions/:id/subscribe
 */
exports.toggleSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const { notifyOnAllComments, notifyOnReplies, notifyOnLikes } = req.body;
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';

    const settings = {};
    if (notifyOnAllComments !== undefined) settings.notifyOnAllComments = notifyOnAllComments;
    if (notifyOnReplies !== undefined) settings.notifyOnReplies = notifyOnReplies;
    if (notifyOnLikes !== undefined) settings.notifyOnLikes = notifyOnLikes;

    const result = await NotificationSubscription.toggleSubscription(
      id,
      userId,
      userType,
      settings
    );

    res.status(200).json({
      success: true,
      message: result.action === 'subscribed' ? 'Subscribed to notifications' : 
               result.action === 'unsubscribed' ? 'Unsubscribed from notifications' : 
               'Notification settings updated',
      data: {
        subscribed: result.subscribed,
        subscription: result.subscription
      }
    });
  } catch (error) {
    console.error('Error toggling subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle subscription',
      error: error.message
    });
  }
};

/**
 * Get user's subscriptions
 * GET /api/discussions/subscriptions
 */
exports.getSubscriptions = async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.userType || 'astrologer';
    const { page = 1, limit = 50 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const subscriptions = await NotificationSubscription.getUserSubscriptions(
      userId,
      userType,
      parseInt(limit),
      skip
    );

    const total = await NotificationSubscription.countDocuments({
      userId,
      userType,
      isActive: true
    });

    res.status(200).json({
      success: true,
      data: subscriptions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching subscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch subscriptions',
      error: error.message
    });
  }
};

// ============================================
// SEARCH & DISCOVERY
// ============================================

/**
 * Search discussions
 * GET /api/discussions/search
 */
exports.searchDiscussions = async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    if (!q || q.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const discussions = await Discussion.find({
      $text: { $search: q },
      isDeleted: false,
      isPublic: true
    })
      .sort({ score: { $meta: 'textScore' } })
      .limit(parseInt(limit))
      .skip(skip)
      .lean();

    const total = await Discussion.countDocuments({
      $text: { $search: q },
      isDeleted: false,
      isPublic: true
    });

    res.status(200).json({
      success: true,
      data: discussions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error searching discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search discussions',
      error: error.message
    });
  }
};

/**
 * Get trending discussions
 * GET /api/discussions/trending
 */
exports.getTrendingDiscussions = async (req, res) => {
  try {
    const { limit = 20, timeframe = '7d' } = req.query;

    // Calculate time threshold
    const now = new Date();
    let timeThreshold;
    switch (timeframe) {
      case '24h':
        timeThreshold = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case '7d':
        timeThreshold = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case '30d':
        timeThreshold = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      default:
        timeThreshold = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    }

    // Recalculate trending scores for recent discussions
    const recentDiscussions = await Discussion.find({
      createdAt: { $gte: timeThreshold },
      isDeleted: false,
      isPublic: true
    });

    for (let discussion of recentDiscussions) {
      discussion.calculateTrendingScore();
      await discussion.save();
    }

    // Get trending discussions
    const discussions = await Discussion.find({
      isDeleted: false,
      isPublic: true,
      createdAt: { $gte: timeThreshold }
    })
      .sort({ trendingScore: -1 })
      .limit(parseInt(limit))
      .lean();

    res.status(200).json({
      success: true,
      data: discussions
    });
  } catch (error) {
    console.error('Error fetching trending discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trending discussions',
      error: error.message
    });
  }
};

/**
 * Get discussions by astrologer
 * GET /api/astrologers/:astrologerId/discussions
 */
exports.getAstrologerDiscussions = async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const discussions = await Discussion.find({
      authorId: astrologerId,
      isDeleted: false,
      isPublic: true
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(skip)
      .lean();

    const total = await Discussion.countDocuments({
      authorId: astrologerId,
      isDeleted: false,
      isPublic: true
    });

    res.status(200).json({
      success: true,
      data: discussions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching astrologer discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch astrologer discussions',
      error: error.message
    });
  }
};

/**
 * Get astrologer public stats
 * GET /api/astrologers/:astrologerId/stats
 */
exports.getAstrologerStats = async (req, res) => {
  try {
    const { astrologerId } = req.params;

    const totalDiscussions = await Discussion.countDocuments({
      authorId: astrologerId,
      isDeleted: false,
      isPublic: true
    });

    const discussions = await Discussion.find({
      authorId: astrologerId,
      isDeleted: false
    }).select('likeCount commentCount viewCount shareCount');

    const totalLikes = discussions.reduce((sum, d) => sum + d.likeCount, 0);
    const totalComments = discussions.reduce((sum, d) => sum + d.commentCount, 0);
    const totalViews = discussions.reduce((sum, d) => sum + d.viewCount, 0);
    const totalShares = discussions.reduce((sum, d) => sum + d.shareCount, 0);

    res.status(200).json({
      success: true,
      data: {
        totalDiscussions,
        totalLikes,
        totalComments,
        totalViews,
        totalShares,
        averageLikesPerPost: totalDiscussions > 0 ? (totalLikes / totalDiscussions).toFixed(2) : 0,
        averageCommentsPerPost: totalDiscussions > 0 ? (totalComments / totalDiscussions).toFixed(2) : 0
      }
    });
  } catch (error) {
    console.error('Error fetching astrologer stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch astrologer stats',
      error: error.message
    });
  }
};

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Send notifications to subscribers when new comment is added
 */
async function sendCommentNotifications(discussionId, comment, commentAuthorId, commentAuthorType) {
  try {
    // Get all active subscribers for this discussion
    const subscribers = await NotificationSubscription.find({
      discussionId,
      isActive: true,
      $or: [
        { notifyOnAllComments: true },
        { 
          notifyOnReplies: true,
          // Only if this is a reply to their comment
          ...(comment.parentCommentId && {
            userId: { $exists: true } // This will be filtered in the next step
          })
        }
      ]
    });

    // Filter subscribers
    for (let subscription of subscribers) {
      // Don't notify the comment author
      if (subscription.userId.toString() === commentAuthorId && 
          subscription.userType === commentAuthorType) {
        continue;
      }

      // If it's a reply, only notify if it's a reply to their comment
      if (comment.parentCommentId && subscription.notifyOnReplies) {
        const parentComment = await DiscussionComment.findById(comment.parentCommentId);
        if (parentComment && 
            parentComment.authorId.toString() === subscription.userId.toString() &&
            parentComment.authorType === subscription.userType) {
          // Send notification (implement your notification service here)
          console.log(`Sending reply notification to ${subscription.userId}`);
        }
      } else if (subscription.notifyOnAllComments) {
        // Send notification for all comments
        console.log(`Sending comment notification to ${subscription.userId}`);
      }

      // Update last notified time
      await subscription.updateLastNotified();
    }
  } catch (error) {
    console.error('Error sending comment notifications:', error);
  }
}

