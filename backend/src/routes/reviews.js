const express = require('express');
const router = express.Router();
const reviewsController = require('../controllers/reviewsController');
const auth = require('../middleware/auth');

// Public endpoint for testing (no auth required)
router.get('/public', reviewsController.getReviews);

// Apply authentication middleware to all other routes
router.use(auth);

// GET /api/reviews/stats - Get rating statistics
router.get('/stats', reviewsController.getRatingStats);

// GET /api/reviews - Get all reviews with filters
router.get('/', reviewsController.getReviews);

// POST /api/reviews/:id/reply - Reply to a review
router.post('/:id/reply', reviewsController.replyToReview);

module.exports = router;
