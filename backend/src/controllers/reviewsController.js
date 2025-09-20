// const Review = require('../models/Review'); // Using mock data for now
const { validationResult } = require('express-validator');

// GET /api/reviews/stats - Get rating statistics
const getRatingStats = async (req, res) => {
  try {
    const astrologerId = req.user.id;
    
    // For now, we'll use mock data since we don't have a real database
    // In production, you would query your actual database
    const mockStats = {
      averageRating: 4.8,
      totalReviews: 156,
      ratingBreakdown: {
        5: 120,
        4: 25,
        3: 8,
        2: 2,
        1: 1
      },
      unrespondedCount: 12
    };
    
    res.json({
      success: true,
      data: mockStats
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
    
    // Mock data for demonstration
    const mockReviews = [
      {
        _id: '1',
        clientName: 'Sarah Johnson',
        clientAvatar: '',
        rating: 5,
        reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: null,
        repliedAt: null,
        sessionId: 'session_1',
        isPublic: true
      },
      {
        _id: '2',
        clientName: 'Michael Chen',
        clientAvatar: '',
        rating: 4,
        reviewText: 'Good session, got some valuable insights. The astrologer was professional and answered all my questions.',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: 'Thank you for your feedback, Michael! I\'m glad I could help you gain clarity.',
        repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
        sessionId: 'session_2',
        isPublic: true
      },
      {
        _id: '3',
        clientName: 'Emily Rodriguez',
        clientAvatar: '',
        rating: 5,
        reviewText: 'Exceptional service! The reading was spot on and the guidance provided was exactly what I needed.',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: null,
        repliedAt: null,
        sessionId: 'session_3',
        isPublic: true
      },
      {
        _id: '4',
        clientName: 'David Kim',
        clientAvatar: '',
        rating: 3,
        reviewText: 'The session was okay, but I expected more detailed explanations. Some points were unclear.',
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: null,
        repliedAt: null,
        sessionId: 'session_4',
        isPublic: true
      },
      {
        _id: '5',
        clientName: 'Lisa Thompson',
        clientAvatar: '',
        rating: 5,
        reviewText: 'Outstanding consultation! The astrologer was very knowledgeable and provided clear guidance. Will definitely book again.',
        createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: 'Thank you so much, Lisa! I look forward to our next session.',
        repliedAt: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000).toISOString(),
        sessionId: 'session_5',
        isPublic: true
      },
      {
        _id: '6',
        clientName: 'James Wilson',
        clientAvatar: '',
        rating: 4,
        reviewText: 'Good experience overall. The astrologer was patient and explained things well.',
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        astrologerReply: null,
        repliedAt: null,
        sessionId: 'session_6',
        isPublic: true
      }
    ];
    
    // Apply filters
    let filteredReviews = mockReviews;
    
    if (rating) {
      const ratingNum = parseInt(rating);
      filteredReviews = filteredReviews.filter(review => review.rating === ratingNum);
    }
    
    if (needsReply === 'true') {
      filteredReviews = filteredReviews.filter(review => !review.astrologerReply);
    }
    
    // Apply sorting
    if (sortBy === 'oldest') {
      filteredReviews.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    } else if (sortBy === 'rating_high') {
      filteredReviews.sort((a, b) => b.rating - a.rating);
    } else if (sortBy === 'rating_low') {
      filteredReviews.sort((a, b) => a.rating - b.rating);
    } else {
      // Default: newest first
      filteredReviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }
    
    // Apply pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedReviews = filteredReviews.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedReviews
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
    
    // In a real application, you would update the database here
    // For now, we'll just return a success response
    console.log(`Astrologer ${astrologerId} replied to review ${id}: ${replyText}`);
    
    res.json({
      success: true,
      message: 'Reply submitted successfully',
      data: {
        reviewId: id,
        astrologerReply: replyText,
        repliedAt: new Date().toISOString()
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
