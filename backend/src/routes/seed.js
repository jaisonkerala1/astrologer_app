const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Review = require('../models/Review');

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
    console.log('MongoDB connection state:', mongoose.connection.readyState);
    
    // Ensure mongoose connection is ready
    if (mongoose.connection.readyState !== 1) {
      console.log('MongoDB not connected, waiting for connection...');
      await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error('MongoDB connection timeout'));
        }, 10000);
        
        if (mongoose.connection.readyState === 1) {
          clearTimeout(timeout);
          resolve();
        } else {
          mongoose.connection.once('open', () => {
            clearTimeout(timeout);
            resolve();
          });
        }
      });
    }
    
    // Clear existing reviews for this astrologer
    await Review.deleteMany({ astrologerId: new mongoose.Types.ObjectId(astrologerId) });
    
    // Mock client IDs
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
    
    // Create reviews data directly
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
    
    // Insert reviews directly
    const createdReviews = await Review.insertMany(reviewsData);
    
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
