const express = require('express');
const router = express.Router();
const { seedReviewsForAstrologer } = require('../scripts/seedReviews');

// POST /api/seed/reviews - Seed reviews for the authenticated astrologer
router.post('/reviews', async (req, res) => {
  try {
    // Allow seeding in development or with special header for Railway testing
    const allowSeeding = process.env.NODE_ENV !== 'production' || 
                         req.headers['x-seed-key'] === 'dev-seed-reviews-2025';
    
    if (!allowSeeding) {
      return res.status(403).json({
        success: false,
        message: 'Seeding not allowed in production without proper authorization'
      });
    }

    const astrologerId = '68ccff521b39ed18eb9eaff3'; // Your astrologer ID
    
    console.log('🌱 Seeding reviews for astrologer:', astrologerId);
    const createdReviews = await seedReviewsForAstrologer(astrologerId);
    
    const ratings = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    createdReviews.forEach(review => {
      ratings[review.rating]++;
    });
    
    const withReplies = createdReviews.filter(r => r.astrologerReply).length;
    const needingReplies = createdReviews.length - withReplies;
    
    res.json({
      success: true,
      message: 'Reviews seeded successfully',
      data: {
        totalReviews: createdReviews.length,
        ratingDistribution: ratings,
        withReplies,
        needingReplies
      }
    });
  } catch (error) {
    console.error('Error seeding reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to seed reviews',
      error: error.message
    });
  }
});

module.exports = router;
