// MINIMAL WORKING CONTROLLER - NO DEPENDENCIES

// GET /api/reviews/stats - Get rating statistics
const getRatingStats = async (req, res) => {
  try {
    console.log('Getting rating stats...');
    
    // Return mock data immediately - no database queries
    const result = {
      averageRating: 4.4,
      totalReviews: 5,
      ratingBreakdown: { 1: 0, 2: 0, 3: 1, 4: 2, 5: 2 },
      unrespondedCount: 3
    };
    
    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    console.error('Error getting rating stats:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get rating statistics' 
    });
  }
};

// GET /api/reviews - Get all reviews
const getReviews = async (req, res) => {
  try {
    console.log('Getting reviews...');
    
    // Return mock data immediately - no database queries
    const reviews = [
      {
        _id: '507f1f77bcf86cd799439011',
        clientName: 'Sarah Johnson',
        rating: 5,
        reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true
      },
      {
        _id: '507f1f77bcf86cd799439012',
        clientName: 'Michael Chen',
        rating: 4,
        reviewText: 'Good session, got some valuable insights. The astrologer was professional and answered all my questions.',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        astrologerReply: 'Thank you for your feedback, Michael! I\'m glad I could help you gain clarity.',
        repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
        isPublic: true
      },
      {
        _id: '507f1f77bcf86cd799439013',
        clientName: 'Emily Rodriguez',
        rating: 5,
        reviewText: 'Exceptional service! The reading was spot on and the guidance provided was exactly what I needed.',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true
      },
      {
        _id: '507f1f77bcf86cd799439014',
        clientName: 'David Kim',
        rating: 3,
        reviewText: 'The session was okay, but I expected more detailed explanations. Some points were unclear.',
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true
      },
      {
        _id: '507f1f77bcf86cd799439015',
        clientName: 'Lisa Thompson',
        rating: 5,
        reviewText: 'Outstanding consultation! The astrologer was very knowledgeable and provided clear guidance. Will definitely book again.',
        createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000),
        astrologerReply: 'Thank you so much, Lisa! I look forward to our next session.',
        repliedAt: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000),
        isPublic: true
      }
    ];

    res.json({
      success: true,
      data: reviews
    });

  } catch (error) {
    console.error('Error getting reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get reviews'
    });
  }
};

// POST /api/reviews/:id/reply - Reply to a review
const replyToReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { replyText } = req.body;
    
    console.log(`Replying to review ${id}: ${replyText}`);

    // Return mock success response
    res.json({
      success: true,
      message: 'Reply submitted successfully',
      data: {
        _id: id,
        astrologerReply: replyText,
        repliedAt: new Date()
      }
    });

  } catch (error) {
    console.error('Error replying to review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit reply'
    });
  }
};

module.exports = {
  getRatingStats,
  getReviews,
  replyToReview
};