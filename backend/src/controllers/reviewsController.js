const Review = require('../models/Review');
const mongoose = require('mongoose');

// GET /api/reviews/stats - Get rating statistics
const getRatingStats = async (req, res) => {
  try {
    const astrologerId = req.user.id;
    
    // Professional MongoDB aggregation pipeline for statistics
    const stats = await Review.aggregate([
      {
        $match: { 
          astrologerId: new mongoose.Types.ObjectId(astrologerId),
          isPublic: true,
          isVerified: true
        }
      },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 },
          ratings: { $push: '$rating' },
          unrespondedCount: {
            $sum: {
              $cond: [
                { $eq: ['$astrologerReply', null] },
                1,
                0
              ]
            }
          }
        }
      }
    ]);

    // Calculate rating breakdown
    const ratingBreakdown = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    
    if (stats.length > 0 && stats[0].ratings) {
      stats[0].ratings.forEach(rating => {
        ratingBreakdown[rating] = (ratingBreakdown[rating] || 0) + 1;
      });
    }

    const result = {
      averageRating: stats.length > 0 ? Math.round(stats[0].averageRating * 10) / 10 : 0,
      totalReviews: stats.length > 0 ? stats[0].totalReviews : 0,
      ratingBreakdown,
      unrespondedCount: stats.length > 0 ? stats[0].unrespondedCount : 0
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

// GET /api/reviews - Get all reviews with filters
const getReviews = async (req, res) => {
  try {
    const astrologerId = req.user.id;
    const { rating, needsReply, sortBy, page = 1, limit = 20 } = req.query;
    
    // Build MongoDB query filters
    const filter = {
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      isPublic: true,
      isVerified: true
    };

    // Apply rating filter
    if (rating) {
      filter.rating = parseInt(rating);
    }

    // Apply needs reply filter
    if (needsReply === 'true') {
      filter.astrologerReply = null;
    }

    // Build sort options
    let sortOptions = { createdAt: -1 }; // Default: newest first
    
    if (sortBy === 'oldest') {
      sortOptions = { createdAt: 1 };
    } else if (sortBy === 'rating_high') {
      sortOptions = { rating: -1, createdAt: -1 };
    } else if (sortBy === 'rating_low') {
      sortOptions = { rating: 1, createdAt: -1 };
    }

    // Professional MongoDB query with aggregation pipeline for client data
    const reviews = await Review.aggregate([
      { $match: filter },
      {
        $addFields: {
          // Add client info from seedReviews mockClients data
          // In real app, this would be $lookup to actual User collection
          clientName: {
            $switch: {
              branches: [
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123456')] }, then: 'Sarah Johnson' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123457')] }, then: 'Michael Chen' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123458')] }, then: 'Emily Rodriguez' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123459')] }, then: 'David Kim' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123460')] }, then: 'Lisa Thompson' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123461')] }, then: 'James Wilson' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123462')] }, then: 'Maria Garcia' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123463')] }, then: 'Robert Brown' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123464')] }, then: 'Jennifer Davis' },
                { case: { $eq: ['$clientId', new mongoose.Types.ObjectId('64a123456789abcdef123465')] }, then: 'Christopher Miller' }
              ],
              default: 'Anonymous'
            }
          },
          clientAvatar: ''
        }
      },
      { $sort: sortOptions },
      { $skip: (parseInt(page) - 1) * parseInt(limit) },
      { $limit: parseInt(limit) }
    ]);

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
    const astrologerId = req.user.id;
    
    // Validate input
    if (!replyText || replyText.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Reply text is required'
      });
    }
    
    if (replyText.length > 500) {
      return res.status(400).json({
        success: false,
        message: 'Reply text must be less than 500 characters'
      });
    }

    // Professional MongoDB update operation
    const updatedReview = await Review.findOneAndUpdate(
      { 
        _id: new mongoose.Types.ObjectId(id),
        astrologerId: new mongoose.Types.ObjectId(astrologerId)
      },
      { 
        astrologerReply: replyText.trim(),
        repliedAt: new Date()
      },
      { 
        new: true // Return updated document
      }
    );

    if (!updatedReview) {
      return res.status(404).json({
        success: false,
        message: 'Review not found or you are not authorized to reply to this review'
      });
    }
    
    res.json({
      success: true,
      message: 'Reply submitted successfully',
      data: {
        reviewId: id,
        astrologerReply: replyText,
        repliedAt: updatedReview.repliedAt
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
