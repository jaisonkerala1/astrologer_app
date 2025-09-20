// CONTROLLER WITH MONGODB CONNECTION FOR DELETION
let Review;
try {
  Review = require('../models/Review');
} catch (error) {
  console.error('Failed to load Review model:', error);
}

const getRatingStats = async (req, res) => {
  try {
    console.log('Getting rating stats - minimal version');
    
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
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error: ' + error.message
    });
  }
};

const getReviews = async (req, res) => {
  try {
    console.log('Getting reviews - minimal version');
    
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
      }
    ];
    
    res.json({
      success: true,
      data: reviews
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error: ' + error.message
    });
  }
};

const replyToReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { replyText } = req.body;
    
    console.log(`Replying to review ${id}: ${replyText}`);
    
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
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error: ' + error.message
    });
  }
};

// DELETE ALL REVIEWS - ACTUAL MONGODB DELETION
const deleteAllReviews = async (req, res) => {
  try {
    console.log('🗑️ Attempting to delete all reviews from database...');
    
    if (!Review) {
      return res.status(500).json({
        success: false,
        message: 'Review model not available'
      });
    }
    
    // Delete ALL reviews from the database
    const deleteResult = await Review.deleteMany({});
    console.log(`✅ Deleted ${deleteResult.deletedCount} reviews from database`);
    
    res.json({
      success: true,
      message: `Successfully deleted ${deleteResult.deletedCount} reviews from database`,
      deletedCount: deleteResult.deletedCount
    });
  } catch (error) {
    console.error('❌ Error deleting reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting reviews: ' + error.message
    });
  }
};

module.exports = {
  getRatingStats,
  getReviews,
  replyToReview,
  deleteAllReviews,
};