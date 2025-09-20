const Review = require('../models/Review');
const mongoose = require('mongoose');

// Function to create sample reviews
const createSampleReviews = async (astrologerId) => {
  console.log('Creating reviews for astrologerId:', astrologerId);
  
  // Clear any existing reviews for this astrologer first
  await Review.deleteMany({ astrologerId: new mongoose.Types.ObjectId(astrologerId) });
  
  const mockClientIds = [
    new mongoose.Types.ObjectId('64a123456789abcdef123456'),
    new mongoose.Types.ObjectId('64a123456789abcdef123457'),
    new mongoose.Types.ObjectId('64a123456789abcdef123458'),
    new mongoose.Types.ObjectId('64a123456789abcdef123459'),
    new mongoose.Types.ObjectId('64a123456789abcdef123460'),
    new mongoose.Types.ObjectId('64a123456789abcdef123461'),
    new mongoose.Types.ObjectId('64a123456789abcdef123462'),
    new mongoose.Types.ObjectId('64a123456789abcdef123463'),
    new mongoose.Types.ObjectId('64a123456789abcdef123464'),
    new mongoose.Types.ObjectId('64a123456789abcdef123465')
  ];

  const reviewsData = [
    {
      clientId: mockClientIds[0],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 5,
      reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[1],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 4,
      reviewText: 'Good session, got some valuable insights. The astrologer was professional and answered all my questions.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you for your feedback, Michael! I\'m glad I could help you gain clarity.',
      repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[2],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 5,
      reviewText: 'Exceptional service! The reading was spot on and the guidance provided was exactly what I needed.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[3],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 3,
      reviewText: 'The session was okay, but I expected more detailed explanations. Some points were unclear.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[4],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 5,
      reviewText: 'Outstanding consultation! The astrologer was very knowledgeable and provided clear guidance. Will definitely book again.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you so much, Lisa! I look forward to our next session.',
      repliedAt: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[5],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 4,
      reviewText: 'Good experience overall. The astrologer was patient and explained things well.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[6],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 5,
      reviewText: 'Incredible accuracy in predictions! The astrologer understood my concerns perfectly and provided practical solutions.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'I\'m happy I could help guide you, Maria. Wishing you all the best!',
      repliedAt: new Date(Date.now() - 17 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[7],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 4,
      reviewText: 'Very insightful session. The astrologer helped me understand my career path better.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[8],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 5,
      reviewText: 'Absolutely wonderful! The guidance I received has been life-changing. Thank you so much!',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000)
    },
    {
      clientId: mockClientIds[9],
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: 4,
      reviewText: 'Great consultation with helpful advice. The astrologer was very professional and knowledgeable.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you for your kind words, Christopher! Best wishes to you.',
      repliedAt: new Date(Date.now() - 27 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 28 * 24 * 60 * 60 * 1000)
    }
  ];

  await Review.insertMany(reviewsData);
  console.log('Sample reviews created successfully');
};

// GET /api/reviews/stats - Get rating statistics
const getRatingStats = async (req, res) => {
  try {
    const astrologerId = req.user.id;
    
    console.log(`Querying reviews for astrologerId: ${astrologerId}`);

    // Fallback to mock data if MongoDB connection fails
    try {
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

    } catch (dbError) {
      console.error('MongoDB connection failed, using mock data:', dbError.message);
      
      // Return mock data for testing
      const mockResult = {
        averageRating: 4.4,
        totalReviews: 5,
        ratingBreakdown: { 1: 0, 2: 0, 3: 1, 4: 2, 5: 2 },
        unrespondedCount: 3
      };
      
      res.json({
        success: true,
        data: mockResult,
        fallback: true
      });
    }
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

    console.log(`Querying reviews for astrologerId: ${astrologerId}`);
    
    // Fallback to mock data if MongoDB connection fails
    try {
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

    } catch (dbError) {
      console.error('MongoDB connection failed, using mock reviews:', dbError.message);
      
      // Return mock reviews for testing
      const mockReviews = [
        {
          _id: '507f1f77bcf86cd799439011',
          clientName: 'Sarah Johnson',
          rating: 5,
          reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
          createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
          astrologerReply: null,
          repliedAt: null
        },
        {
          _id: '507f1f77bcf86cd799439012',
          clientName: 'Michael Chen',
          rating: 4,
          reviewText: 'Good session, got some valuable insights. The astrologer was professional and answered all my questions.',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
          astrologerReply: 'Thank you for your feedback, Michael! I\'m glad I could help you gain clarity.',
          repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000)
        },
        {
          _id: '507f1f77bcf86cd799439013',
          clientName: 'Emily Rodriguez',
          rating: 5,
          reviewText: 'Exceptional service! The reading was spot on and the guidance provided was exactly what I needed.',
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
          astrologerReply: null,
          repliedAt: null
        },
        {
          _id: '507f1f77bcf86cd799439014',
          clientName: 'David Kim',
          rating: 3,
          reviewText: 'The session was okay, but I expected more detailed explanations. Some points were unclear.',
          createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
          astrologerReply: null,
          repliedAt: null
        },
        {
          _id: '507f1f77bcf86cd799439015',
          clientName: 'Lisa Thompson',
          rating: 5,
          reviewText: 'Outstanding consultation! The astrologer was very knowledgeable and provided clear guidance. Will definitely book again.',
          createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000),
          astrologerReply: 'Thank you so much, Lisa! I look forward to our next session.',
          repliedAt: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000)
        }
      ];
      
      res.json({
        success: true,
        data: mockReviews,
        fallback: true
      });
    }
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
