const express = require('express');
const router = express.Router();
const discussionController = require('../controllers/discussionController');
const auth = require('../middleware/auth');
const optionalAuth = require('../middleware/optionalAuth');

// ============================================
// DISCUSSION CRUD ROUTES
// ============================================

/**
 * @route   POST /api/discussions
 * @desc    Create new discussion
 * @access  Private (Astrologers only)
 */
router.post('/', auth, discussionController.createDiscussion);

/**
 * @route   GET /api/discussions
 * @desc    Get all discussions with filters and pagination
 * @access  Public/Private (different visibility based on auth)
 * @query   page, limit, sortBy, sortOrder, category, tags, authorId, visibleTo, search
 * NOTE: Optional auth - sets req.user if token provided (for isLiked status)
 */
router.get('/', optionalAuth, discussionController.getDiscussions);

/**
 * @route   GET /api/discussions/my-posts
 * @desc    Get current user's discussions
 * @access  Private
 */
router.get('/my-posts', auth, discussionController.getMyDiscussions);

/**
 * @route   GET /api/discussions/saved
 * @desc    Get user's saved posts
 * @access  Private
 */
router.get('/saved', auth, discussionController.getSavedPosts);

/**
 * @route   GET /api/discussions/subscriptions
 * @desc    Get user's notification subscriptions
 * @access  Private
 */
router.get('/subscriptions', auth, discussionController.getSubscriptions);

/**
 * @route   GET /api/discussions/search
 * @desc    Search discussions
 * @access  Public
 * @query   q (search query), page, limit
 */
router.get('/search', discussionController.searchDiscussions);

/**
 * @route   GET /api/discussions/trending
 * @desc    Get trending discussions
 * @access  Public
 * @query   limit, timeframe (24h, 7d, 30d)
 */
router.get('/trending', discussionController.getTrendingDiscussions);

/**
 * @route   GET /api/discussions/:id
 * @desc    Get single discussion by ID
 * @access  Public/Private
 */
router.get('/:id', discussionController.getDiscussionById);

/**
 * @route   PUT /api/discussions/:id
 * @desc    Update discussion (author only)
 * @access  Private
 */
router.put('/:id', auth, discussionController.updateDiscussion);

/**
 * @route   DELETE /api/discussions/:id
 * @desc    Delete discussion (soft delete, author only)
 * @access  Private
 */
router.delete('/:id', auth, discussionController.deleteDiscussion);

// ============================================
// ENGAGEMENT ROUTES
// ============================================

/**
 * @route   POST /api/discussions/:id/like
 * @desc    Toggle like on discussion
 * @access  Private
 */
router.post('/:id/like', auth, discussionController.toggleLike);

/**
 * @route   GET /api/discussions/:id/likes
 * @desc    Get users who liked discussion
 * @access  Public
 */
router.get('/:id/likes', discussionController.getDiscussionLikes);

/**
 * @route   POST /api/discussions/:id/view
 * @desc    Increment view count
 * @access  Public
 */
router.post('/:id/view', discussionController.incrementView);

/**
 * @route   POST /api/discussions/:id/share
 * @desc    Increment share count
 * @access  Public
 */
router.post('/:id/share', discussionController.incrementShare);

/**
 * @route   POST /api/discussions/:id/save
 * @desc    Toggle save on discussion (bookmark)
 * @access  Private
 */
router.post('/:id/save', auth, discussionController.toggleSave);

/**
 * @route   POST /api/discussions/:id/subscribe
 * @desc    Toggle notification subscription for discussion
 * @access  Private
 * @body    notifyOnAllComments, notifyOnReplies, notifyOnLikes (optional)
 */
router.post('/:id/subscribe', auth, discussionController.toggleSubscription);

// ============================================
// COMMENT ROUTES
// ============================================

/**
 * @route   POST /api/discussions/:id/comments
 * @desc    Add comment to discussion
 * @access  Private
 * @body    text, imageUrl (optional), parentCommentId (optional for replies)
 */
router.post('/:id/comments', auth, discussionController.addComment);

/**
 * @route   GET /api/discussions/:id/comments
 * @desc    Get comments for discussion
 * @access  Public
 * @query   page, limit, structure (flat or nested)
 */
router.get('/:id/comments', discussionController.getComments);

/**
 * @route   PUT /api/comments/:commentId
 * @desc    Update comment (author only)
 * @access  Private
 */
router.put('/comments/:commentId', auth, discussionController.updateComment);

/**
 * @route   DELETE /api/comments/:commentId
 * @desc    Delete comment (soft delete, author or discussion author)
 * @access  Private
 */
router.delete('/comments/:commentId', auth, discussionController.deleteComment);

/**
 * @route   POST /api/comments/:commentId/like
 * @desc    Toggle like on comment
 * @access  Private
 */
router.post('/comments/:commentId/like', auth, discussionController.toggleCommentLike);

/**
 * @route   GET /api/comments/:commentId/likes
 * @desc    Get users who liked comment
 * @access  Public
 */
router.get('/comments/:commentId/likes', discussionController.getCommentLikes);

// ============================================
// ASTROLOGER PUBLIC PROFILE ROUTES
// ============================================

/**
 * @route   GET /api/astrologers/:astrologerId/discussions
 * @desc    Get discussions by specific astrologer
 * @access  Public
 */
router.get('/astrologers/:astrologerId/discussions', discussionController.getAstrologerDiscussions);

/**
 * @route   GET /api/astrologers/:astrologerId/stats
 * @desc    Get astrologer's public discussion stats
 * @access  Public
 */
router.get('/astrologers/:astrologerId/stats', discussionController.getAstrologerStats);

module.exports = router;

