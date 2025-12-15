const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const Discussion = require('../models/Discussion');
const DiscussionComment = require('../models/DiscussionComment');
const Astrologer = require('../models/Astrologer');
const auth = require('../middleware/auth');
const EVENTS = require('../socket/events');

// Rate limiters
const createPostLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // Max 5 posts per minute
  message: { success: false, message: 'Too many posts. Please wait a moment.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const commentLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20, // Max 20 comments per minute
  message: { success: false, message: 'Too many comments. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const likeLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // Max 60 likes per minute (generous for rapid liking)
  message: { success: false, message: 'Too many like actions. Please wait.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Get all discussions (paginated)
 * GET /api/discussion
 * Query params: page, limit, category, sortBy, sortOrder
 */
router.get('/', auth, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      category,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      visibility = 'public'
    } = req.query;

    const result = await Discussion.getPaginated({
      page: parseInt(page),
      limit: parseInt(limit),
      category: category || null,
      sortBy,
      sortOrder: sortOrder === 'asc' ? 1 : -1,
      visibility,
      userId: req.user.astrologerId // For checking isLiked
    });

    // Transform for Flutter
    const discussions = result.discussions.map(d => ({
      id: d._id.toString(),
      title: d.title,
      content: d.content,
      category: d.category,
      author: d.authorName,
      authorId: d.authorId.toString(),
      authorInitial: d.authorName ? d.authorName.charAt(0).toUpperCase() : '?',
      authorAvatar: d.authorAvatar,
      likes: d.likesCount,
      isLiked: d.isLiked,
      commentsCount: d.commentsCount,
      visibility: d.visibility,
      isPinned: d.isPinned,
      createdAt: d.createdAt,
      timeAgo: getTimeAgo(d.createdAt)
    }));

    res.json({
      success: true,
      data: discussions,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error fetching discussions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch discussions'
    });
  }
});

/**
 * Get discussions by current user (my posts)
 * GET /api/discussion/my-posts
 */
router.get('/my-posts', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const result = await Discussion.getPaginated({
      page: parseInt(page),
      limit: parseInt(limit),
      authorId: req.user.astrologerId,
      visibility: null, // Show all visibility for own posts
      userId: req.user.astrologerId
    });

    const discussions = result.discussions.map(d => ({
      id: d._id.toString(),
      title: d.title,
      content: d.content,
      category: d.category,
      author: d.authorName,
      authorId: d.authorId.toString(),
      authorInitial: d.authorName ? d.authorName.charAt(0).toUpperCase() : '?',
      authorAvatar: d.authorAvatar,
      likes: d.likesCount,
      isLiked: d.isLiked,
      commentsCount: d.commentsCount,
      visibility: d.visibility,
      isPinned: d.isPinned,
      createdAt: d.createdAt,
      timeAgo: getTimeAgo(d.createdAt)
    }));

    res.json({
      success: true,
      data: discussions,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error fetching my posts:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch your posts'
    });
  }
});

/**
 * Get single discussion with details
 * GET /api/discussion/:id
 */
router.get('/:id', auth, async (req, res) => {
  try {
    const discussion = await Discussion.findById(req.params.id);

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    const isLiked = discussion.isLikedBy(req.user.astrologerId);

    res.json({
      success: true,
      data: {
        id: discussion._id.toString(),
        title: discussion.title,
        content: discussion.content,
        category: discussion.category,
        author: discussion.authorName,
        authorId: discussion.authorId.toString(),
        authorInitial: discussion.authorName ? discussion.authorName.charAt(0).toUpperCase() : '?',
        authorAvatar: discussion.authorAvatar,
        likes: discussion.likesCount,
        isLiked,
        commentsCount: discussion.commentsCount,
        visibility: discussion.visibility,
        isPinned: discussion.isPinned,
        createdAt: discussion.createdAt,
        timeAgo: getTimeAgo(discussion.createdAt)
      }
    });
  } catch (error) {
    console.error('Error fetching discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch discussion'
    });
  }
});

/**
 * Create new discussion
 * POST /api/discussion
 */
router.post('/', auth, createPostLimiter, async (req, res) => {
  try {
    const { title, content, category, visibility = 'public', tags } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    // Get author info
    const author = await Astrologer.findById(req.user.astrologerId);
    if (!author) {
      return res.status(404).json({
        success: false,
        message: 'Author not found'
      });
    }

    const discussion = new Discussion({
      authorId: author._id,
      authorName: author.name,
      authorAvatar: author.profilePicture,
      title: title.trim(),
      content: content.trim(),
      category: category || 'General Discussion',
      visibility,
      tags: tags || []
    });

    await discussion.save();

    // Emit socket event for real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit(EVENTS.DISCUSSION.UPDATE, {
        type: 'new_post',
        discussion: {
          id: discussion._id.toString(),
          title: discussion.title,
          content: discussion.content,
          category: discussion.category,
          author: discussion.authorName,
          authorId: discussion.authorId.toString(),
          authorInitial: discussion.authorName.charAt(0).toUpperCase(),
          authorAvatar: discussion.authorAvatar,
          likes: 0,
          isLiked: false,
          commentsCount: 0,
          createdAt: discussion.createdAt,
          timeAgo: 'Just now'
        }
      });
    }

    console.log(`📝 [DISCUSSION] New post created: ${discussion.title} by ${author.name}`);

    res.status(201).json({
      success: true,
      data: {
        id: discussion._id.toString(),
        title: discussion.title,
        content: discussion.content,
        category: discussion.category,
        author: discussion.authorName,
        authorId: discussion.authorId.toString(),
        authorInitial: discussion.authorName.charAt(0).toUpperCase(),
        authorAvatar: discussion.authorAvatar,
        likes: 0,
        isLiked: false,
        commentsCount: 0,
        visibility: discussion.visibility,
        createdAt: discussion.createdAt,
        timeAgo: 'Just now'
      },
      message: 'Discussion created successfully'
    });
  } catch (error) {
    console.error('Error creating discussion:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create discussion'
    });
  }
});

/**
 * Update discussion
 * PUT /api/discussion/:id
 */
router.put('/:id', auth, async (req, res) => {
  try {
    const { title, content, category, visibility } = req.body;

    const discussion = await Discussion.findById(req.params.id);

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Check ownership
    if (discussion.authorId.toString() !== req.user.astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to edit this discussion'
      });
    }

    // Update fields
    if (title) discussion.title = title.trim();
    if (content) discussion.content = content.trim();
    if (category) discussion.category = category;
    if (visibility) discussion.visibility = visibility;

    await discussion.save();

    console.log(`✏️ [DISCUSSION] Post updated: ${discussion.title}`);

    res.json({
      success: true,
      data: {
        id: discussion._id.toString(),
        title: discussion.title,
        content: discussion.content,
        category: discussion.category,
        visibility: discussion.visibility,
        updatedAt: discussion.updatedAt
      },
      message: 'Discussion updated successfully'
    });
  } catch (error) {
    console.error('Error updating discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update discussion'
    });
  }
});

/**
 * Delete discussion (soft delete)
 * DELETE /api/discussion/:id
 */
router.delete('/:id', auth, async (req, res) => {
  try {
    const discussion = await Discussion.findById(req.params.id);

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Check ownership
    if (discussion.authorId.toString() !== req.user.astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this discussion'
      });
    }

    // Soft delete
    discussion.isActive = false;
    await discussion.save();

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.emit(EVENTS.DISCUSSION.DELETE, {
        discussionId: discussion._id.toString()
      });
    }

    console.log(`🗑️ [DISCUSSION] Post deleted: ${discussion.title}`);

    res.json({
      success: true,
      message: 'Discussion deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting discussion:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete discussion'
    });
  }
});

/**
 * Toggle like on discussion
 * POST /api/discussion/:id/like
 */
router.post('/:id/like', auth, likeLimiter, async (req, res) => {
  try {
    const discussion = await Discussion.findById(req.params.id);

    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    const isNowLiked = await discussion.toggleLike(req.user.astrologerId);

    // Emit socket event for real-time like count update
    const io = req.app.get('io');
    if (io) {
      const roomId = `discussion:${discussion._id.toString()}`;
      
      // Emit to discussion room (for people viewing the post)
      io.to(roomId).emit(EVENTS.DISCUSSION.LIKE, {
        type: 'discussion',
        discussionId: discussion._id.toString(),
        likesCount: discussion.likesCount,
        userId: req.user.astrologerId,
        isLiked: isNowLiked
      });
      
      // Also emit globally for dashboard/list updates
      io.emit(EVENTS.DISCUSSION.UPDATE, {
        type: 'like_updated',
        discussionId: discussion._id.toString(),
        likesCount: discussion.likesCount,
        userId: req.user.astrologerId,
        isLiked: isNowLiked
      });
    }

    console.log(`${isNowLiked ? '❤️' : '💔'} [DISCUSSION] Like toggled on: ${discussion.title}`);

    res.json({
      success: true,
      data: {
        isLiked: isNowLiked,
        likesCount: discussion.likesCount
      }
    });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle like'
    });
  }
});

/**
 * Get comments for discussion
 * GET /api/discussion/:id/comments
 */
router.get('/:id/comments', auth, async (req, res) => {
  try {
    const { page = 1, limit = 50, flat = 'false' } = req.query;

    const discussion = await Discussion.findById(req.params.id);
    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    let result;
    if (flat === 'true') {
      result = await DiscussionComment.getFlat(
        req.params.id,
        req.user.astrologerId,
        { page: parseInt(page), limit: parseInt(limit) }
      );
    } else {
      result = await DiscussionComment.getCommentsWithReplies(
        req.params.id,
        req.user.astrologerId,
        { page: parseInt(page), limit: parseInt(limit) }
      );
    }

    // Transform for Flutter
    const comments = result.comments.map(c => transformComment(c));

    res.json({
      success: true,
      data: comments,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch comments'
    });
  }
});

/**
 * Add comment to discussion
 * POST /api/discussion/:id/comments
 */
router.post('/:id/comments', auth, commentLimiter, async (req, res) => {
  try {
    const { content, parentCommentId } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Comment content is required'
      });
    }

    const discussion = await Discussion.findById(req.params.id);
    if (!discussion) {
      return res.status(404).json({
        success: false,
        message: 'Discussion not found'
      });
    }

    // Get author info
    const author = await Astrologer.findById(req.user.astrologerId);
    if (!author) {
      return res.status(404).json({
        success: false,
        message: 'Author not found'
      });
    }

    // If replying, verify parent comment exists
    if (parentCommentId) {
      const parentComment = await DiscussionComment.findById(parentCommentId);
      if (!parentComment) {
        return res.status(404).json({
          success: false,
          message: 'Parent comment not found'
        });
      }
      // Increment reply count on parent
      await parentComment.incrementReplyCount();
    }

    const comment = new DiscussionComment({
      discussionId: discussion._id,
      parentCommentId: parentCommentId || null,
      authorId: author._id,
      authorName: author.name,
      authorAvatar: author.profilePicture,
      content: content.trim()
    });

    await comment.save();

    // Increment comment count on discussion
    await discussion.incrementCommentCount();

    // Emit socket event for real-time comment
    const io = req.app.get('io');
    if (io) {
      const roomId = `discussion:${discussion._id.toString()}`;
      const commentData = {
        id: comment._id.toString(),
        discussionId: discussion._id.toString(),
        parentCommentId: comment.parentCommentId?.toString() || null,
        author: comment.authorName,
        authorId: comment.authorId.toString(),
        authorInitial: comment.authorName.charAt(0).toUpperCase(),
        authorAvatar: comment.authorAvatar,
        content: comment.content,
        likes: 0,
        isLiked: false,
        repliesCount: 0,
        createdAt: comment.createdAt,
        timeAgo: 'Just now'
      };

      if (parentCommentId) {
        io.to(roomId).emit(EVENTS.DISCUSSION.REPLY, commentData);
      } else {
        io.to(roomId).emit(EVENTS.DISCUSSION.COMMENT, commentData);
      }

      // Also emit update for comment count on discussion list
      io.emit(EVENTS.DISCUSSION.UPDATE, {
        type: 'comment_added',
        discussionId: discussion._id.toString(),
        commentsCount: discussion.commentsCount
      });
    }

    console.log(`💬 [DISCUSSION] ${parentCommentId ? 'Reply' : 'Comment'} added by ${author.name}`);

    res.status(201).json({
      success: true,
      data: {
        id: comment._id.toString(),
        discussionId: discussion._id.toString(),
        parentCommentId: comment.parentCommentId?.toString() || null,
        author: comment.authorName,
        authorId: comment.authorId.toString(),
        authorInitial: comment.authorName.charAt(0).toUpperCase(),
        authorAvatar: comment.authorAvatar,
        content: comment.content,
        likes: 0,
        isLiked: false,
        repliesCount: 0,
        createdAt: comment.createdAt,
        timeAgo: 'Just now'
      },
      message: parentCommentId ? 'Reply added successfully' : 'Comment added successfully'
    });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to add comment'
    });
  }
});

/**
 * Toggle like on comment
 * POST /api/discussion/comment/:id/like
 */
router.post('/comment/:id/like', auth, likeLimiter, async (req, res) => {
  try {
    const comment = await DiscussionComment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    const isNowLiked = await comment.toggleLike(req.user.astrologerId);

    // Emit socket event for real-time like count update
    const io = req.app.get('io');
    if (io) {
      const roomId = `discussion:${comment.discussionId.toString()}`;
      io.to(roomId).emit(EVENTS.DISCUSSION.LIKE, {
        type: 'comment',
        commentId: comment._id.toString(),
        discussionId: comment.discussionId.toString(),
        likesCount: comment.likesCount,
        userId: req.user.astrologerId,
        isLiked: isNowLiked
      });
    }

    res.json({
      success: true,
      data: {
        isLiked: isNowLiked,
        likesCount: comment.likesCount
      }
    });
  } catch (error) {
    console.error('Error toggling comment like:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle like'
    });
  }
});

/**
 * Delete comment (soft delete)
 * DELETE /api/discussion/comment/:id
 */
router.delete('/comment/:id', auth, async (req, res) => {
  try {
    const comment = await DiscussionComment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Check ownership
    if (comment.authorId.toString() !== req.user.astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this comment'
      });
    }

    // Soft delete
    comment.isActive = false;
    await comment.save();

    // Decrement comment count on discussion
    const discussion = await Discussion.findById(comment.discussionId);
    if (discussion) {
      await discussion.decrementCommentCount();
    }

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      const roomId = `discussion:${comment.discussionId.toString()}`;
      io.to(roomId).emit(EVENTS.DISCUSSION.DELETE, {
        type: 'comment',
        commentId: comment._id.toString(),
        discussionId: comment.discussionId.toString()
      });
    }

    res.json({
      success: true,
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete comment'
    });
  }
});

/**
 * Get discussion categories
 * GET /api/discussion/categories
 */
router.get('/meta/categories', auth, async (req, res) => {
  try {
    const categories = [
      'Astrology & Horoscopes',
      'Yoga, Meditation & Mindfulness',
      'Healing & Wellness',
      'Spiritual Growth & Practices',
      'Vedic Rituals & Puja',
      'Vastu & Feng Shui',
      'Tarot & Divination',
      'Numerology & Palmistry',
      'Community Support & Life Talk',
      'General Discussion'
    ];

    res.json({
      success: true,
      data: categories
    });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories'
    });
  }
});

// ============ Helper Functions ============

/**
 * Calculate time ago string from date
 */
function getTimeAgo(date) {
  const now = new Date();
  const diff = now - new Date(date);
  
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const weeks = Math.floor(days / 7);
  const months = Math.floor(days / 30);
  const years = Math.floor(days / 365);

  if (seconds < 60) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;
  if (weeks < 4) return `${weeks}w ago`;
  if (months < 12) return `${months}mo ago`;
  return `${years}y ago`;
}

/**
 * Transform comment for API response
 */
function transformComment(comment) {
  return {
    id: comment._id.toString(),
    discussionId: comment.discussionId.toString(),
    parentCommentId: comment.parentCommentId?.toString() || null,
    author: comment.authorName,
    authorId: comment.authorId.toString(),
    authorInitial: comment.authorName ? comment.authorName.charAt(0).toUpperCase() : '?',
    authorAvatar: comment.authorAvatar,
    content: comment.content,
    likes: comment.likesCount,
    isLiked: comment.isLiked || false,
    repliesCount: comment.repliesCount || 0,
    replies: (comment.replies || []).map(r => transformComment(r)),
    createdAt: comment.createdAt,
    timeAgo: getTimeAgo(comment.createdAt)
  };
}

module.exports = router;

