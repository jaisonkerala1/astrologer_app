// CONTROLLER WITH MONGODB CONNECTION FOR REVIEWS
let Review;
let mongoose;

try {
  Review = require('../models/Review');
  mongoose = require('mongoose');
  console.log('✅ Review model loaded successfully');
} catch (error) {
  console.error('❌ Failed to load Review model:', error);
}

const getRatingStats = async (req, res) => {
  try {
    console.log('Getting rating stats...');
    
    if (!Review) {
      console.log('Review model not available, returning fallback data');
      return res.json({
        success: true,
        data: {
          averageRating: 4.4,
          totalReviews: 5,
          ratingBreakdown: { 1: 0, 2: 0, 3: 1, 4: 2, 5: 2 },
          unrespondedCount: 3
        },
        fallback: true
      });
    }
    
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
      message: 'Error getting rating stats: ' + error.message
    });
  }
};

const getReviews = async (req, res) => {
  try {
    console.log('Getting reviews...');
    
    if (!Review) {
      console.log('Review model not available, returning fallback data');
      const fallbackReviews = [
        {
          _id: '507f1f77bcf86cd799439011',
          clientName: 'Sarah Johnson',
          rating: 5,
          reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
          createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
          astrologerReply: null,
          repliedAt: null,
          isPublic: true
        }
      ];
      
      return res.json({
        success: true,
        data: fallbackReviews,
        fallback: true
      });
    }
    
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
      message: 'Error getting reviews: ' + error.message
    });
  }
};

const replyToReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { replyText } = req.body;
    const astrologerId = req.user.astrologerId;
    
    console.log(`Replying to review ${id} for astrologer ${astrologerId}: ${replyText}`);
    
    if (!Review) {
      return res.json({
        success: true,
        message: 'Mock reply submitted successfully',
        data: { 
          _id: id, 
          astrologerReply: replyText, 
          repliedAt: new Date() 
        },
        fallback: true
      });
    }
    
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
      message: 'Error replying to review: ' + error.message
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