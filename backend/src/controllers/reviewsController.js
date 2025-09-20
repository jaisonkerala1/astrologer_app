// CONTROLLER TO FETCH REVIEWS FROM MONGODB
const Review = require('../models/Review');

const getRatingStats = async (req, res) => {
  try {
    const astrologerId = req.user.astrologerId;
    console.log('Getting stats for astrologer:', astrologerId);
    
    // Get all reviews for this astrologer
    const reviews = await Review.find({ astrologerId: astrologerId });
    console.log('Found reviews:', reviews.length);
    
    if (reviews.length === 0) {
      return res.json({
        success: true,
        data: {
          averageRating: 0,
          totalReviews: 0,
          ratingBreakdown: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
          unrespondedCount: 0
        }
      });
    }
    
    // Calculate statistics
    const totalReviews = reviews.length;
    const averageRating = reviews.reduce((sum, review) => sum + review.rating, 0) / totalReviews;
    
    // Calculate rating breakdown
    const ratingBreakdown = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    reviews.forEach(review => {
      ratingBreakdown[review.rating] = (ratingBreakdown[review.rating] || 0) + 1;
    });
    
    // Count unresponded reviews
    const unrespondedCount = reviews.filter(review => !review.astrologerReply).length;
    
    const result = {
      averageRating: Math.round(averageRating * 10) / 10, // Round to 1 decimal
      totalReviews,
      ratingBreakdown,
      unrespondedCount
    };
    
    console.log('Calculated stats:', result);
    
    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Error getting rating stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get rating statistics: ' + error.message
    });
  }
};

const getReviews = async (req, res) => {
  try {
    const astrologerId = req.user.astrologerId;
    console.log('Getting reviews for astrologer:', astrologerId);
    
    // Get all reviews for this astrologer, sorted by newest first
    const reviews = await Review.find({ astrologerId: astrologerId })
      .sort({ createdAt: -1 })
      .limit(50); // Limit to 50 most recent reviews
    
    console.log('Found reviews:', reviews.length);
    
    // Transform reviews to match frontend format
    const transformedReviews = reviews.map(review => ({
      _id: review._id.toString(),
      clientName: `Client ${review._id.toString().slice(-4)}`, // Use last 4 chars of ID as client name
      rating: review.rating,
      reviewText: review.reviewText,
      createdAt: review.createdAt,
      astrologerReply: review.astrologerReply,
      repliedAt: review.repliedAt,
      isPublic: review.isPublic
    }));
    
    res.json({
      success: true,
      data: transformedReviews
    });
  } catch (error) {
    console.error('Error getting reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get reviews: ' + error.message
    });
  }
};

const replyToReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { replyText } = req.body;
    const astrologerId = req.user.astrologerId;
    
    console.log(`Replying to review ${id} for astrologer ${astrologerId}: ${replyText}`);
    
    const review = await Review.findOneAndUpdate(
      { _id: id, astrologerId: astrologerId },
      { 
        astrologerReply: replyText, 
        repliedAt: new Date() 
      },
      { new: true }
    );
    
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Reply submitted successfully',
      data: { 
        _id: review._id.toString(), 
        astrologerReply: review.astrologerReply, 
        repliedAt: review.repliedAt 
      }
    });
  } catch (error) {
    console.error('Error replying to review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit reply: ' + error.message
    });
  }
};

module.exports = {
  getRatingStats,
  getReviews,
  replyToReview,
};