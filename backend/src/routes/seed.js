const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Review = require('../models/Review');

// POST /api/seed/cleanup - Clean up and recreate reviews for authenticated astrologer
router.post('/cleanup', async (req, res) => {
  try {
    // Allow cleanup in development or with special header for Railway testing
    const allowSeeding = process.env.NODE_ENV !== 'production' || 
                         req.headers['x-seed-key'] === 'dev-seed-reviews-2025';
    
    if (!allowSeeding) {
      return res.status(403).json({
        success: false,
        message: 'Cleanup not allowed in production without proper authorization'
      });
    }

    console.log('🧹 Cleaning up and recreating reviews...');
    
    // Delete ALL reviews in the collection (for cleanup)
    const deleteResult = await Review.deleteMany({});
    console.log(`Deleted ${deleteResult.deletedCount} existing reviews`);
    
    // Now create new reviews with the correct astrologer ID
    const correctAstrologerId = '68ccff521b39ed18eb9eaff3'; // From JWT token
    
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 5,
        reviewText: 'Incredible accuracy in predictions! The astrologer understood my concerns perfectly and provided solutions.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: 'I\'m happy I could help guide you, Maria. Wishing you all the best!',
        repliedAt: new Date(Date.now() - 17 * 24 * 60 * 60 * 1000),
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: mockClientIds[7],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
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

    // Insert the corrected reviews
    const createdReviews = await Review.insertMany(reviewsData);
    console.log(`Created ${createdReviews.length} reviews with correct astrologer ID: ${correctAstrologerId}`);

    res.json({
      success: true,
      message: `Cleanup complete! Deleted ${deleteResult.deletedCount} old reviews and created ${createdReviews.length} new reviews with correct astrologer ID.`,
      deletedCount: deleteResult.deletedCount,
      createdCount: createdReviews.length,
      correctAstrologerId: correctAstrologerId
    });
  } catch (error) {
    console.error('Error during cleanup:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cleanup reviews',
      error: error.message
    });
  }
});

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

    const astrologerId = '68ccff521b39ed18eb9eaff3'; // Your correct astrologer ID
    
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

// POST /api/seed/direct - Create reviews directly without auth checks (for testing)
router.post('/direct', async (req, res) => {
  try {
    // Allow direct seeding for testing
    const allowSeeding = process.env.NODE_ENV !== 'production' || 
                         req.headers['x-seed-key'] === 'dev-seed-reviews-2025';
    
    if (!allowSeeding) {
      return res.status(403).json({
        success: false,
        message: 'Direct seeding not allowed in production without proper authorization'
      });
    }

    console.log('🎯 Direct seeding reviews...');
    
    const correctAstrologerId = '68ccff521b39ed18eb9eaff3';
    
    // Clear existing reviews for this astrologer
    await Review.deleteMany({ astrologerId: new mongoose.Types.ObjectId(correctAstrologerId) });
    
    const mockClientIds = [
      new mongoose.Types.ObjectId('64a123456789abcdef123456'),
      new mongoose.Types.ObjectId('64a123456789abcdef123457'),
      new mongoose.Types.ObjectId('64a123456789abcdef123458'),
      new mongoose.Types.ObjectId('64a123456789abcdef123459'),
      new mongoose.Types.ObjectId('64a123456789abcdef123460')
    ];

    const reviewsData = [
      {
        clientId: mockClientIds[0],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 5,
        reviewText: 'Amazing consultation! Very insightful and helpful.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: mockClientIds[1],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 4,
        reviewText: 'Good session with valuable insights.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: 'Thank you for your feedback!',
        repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: mockClientIds[2],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 5,
        reviewText: 'Exceptional service! Highly recommended.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: mockClientIds[3],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 4,
        reviewText: 'Very helpful and professional.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: 'I appreciate your kind words!',
        repliedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: mockClientIds[4],
        astrologerId: new mongoose.Types.ObjectId(correctAstrologerId),
        rating: 5,
        reviewText: 'Outstanding consultation! Will book again.',
        sessionId: new mongoose.Types.ObjectId(),
        astrologerReply: null,
        repliedAt: null,
        isPublic: true,
        isVerified: true,
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000)
      }
    ];

    const createdReviews = await Review.insertMany(reviewsData);
    console.log(`✅ Created ${createdReviews.length} reviews for astrologer ${correctAstrologerId}`);

    res.json({
      success: true,
      message: `Successfully created ${createdReviews.length} reviews with correct astrologer ID.`,
      createdCount: createdReviews.length,
      astrologerId: correctAstrologerId,
      reviewIds: createdReviews.map(r => r._id)
    });

  } catch (error) {
    console.error('Error in direct seeding:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create reviews directly',
      error: error.message
    });
  }
});

// POST /api/seed/add-test-review - Add a test review for any astrologer
router.post('/add-test-review', async (req, res) => {
  try {
    // Allow seeding in development or with special header for Railway testing
    const allowSeeding = process.env.NODE_ENV !== 'production' || 
                         req.headers['x-seed-key'] === 'dev-seed-reviews-2025';
    
    if (!allowSeeding) {
      return res.status(403).json({
        success: false,
        message: 'Test review seeding not allowed in production without proper authorization'
      });
    }

    const { astrologerId, clientId, rating, reviewText } = req.body;
    
    if (!astrologerId) {
      return res.status(400).json({
        success: false,
        message: 'astrologerId is required'
      });
    }

    console.log('🎯 Adding test review for astrologer:', astrologerId);
    
    // Create test review
    const testReview = new Review({
      clientId: new mongoose.Types.ObjectId(clientId || '64a123456789abcdef123999'),
      astrologerId: new mongoose.Types.ObjectId(astrologerId),
      rating: rating || 5,
      reviewText: reviewText || 'Test review for second astrologer account - This is a test review to verify the security fix is working correctly!',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date()
    });

    const savedReview = await testReview.save();
    console.log('✅ Test review created:', savedReview._id);

    res.json({
      success: true,
      message: 'Test review added successfully',
      data: {
        reviewId: savedReview._id,
        astrologerId: savedReview.astrologerId,
        rating: savedReview.rating,
        reviewText: savedReview.reviewText,
        createdAt: savedReview.createdAt
      }
    });

  } catch (error) {
    console.error('Error adding test review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add test review',
      error: error.message
    });
  }
});

// GET /api/seed/debug - Debug what's in the database
router.get('/debug', async (req, res) => {
  try {
    console.log('🔍 Debugging database state...');
    
    // Get ALL reviews in the database
    const allReviews = await Review.find({}).select('astrologerId clientId rating reviewText createdAt').limit(50);
    console.log(`Found ${allReviews.length} total reviews in database`);
    
    // Get reviews for the specific astrologer ID
    const targetAstrologerId = '68ccff521b39ed18eb9eaff3';
    const userReviews = await Review.find({ 
      astrologerId: new mongoose.Types.ObjectId(targetAstrologerId)
    }).select('astrologerId clientId rating reviewText createdAt');
    
    console.log(`Found ${userReviews.length} reviews for target astrologer ${targetAstrologerId}`);
    
    // Get reviews with all filters like the controller uses
    const filteredReviews = await Review.find({ 
      astrologerId: new mongoose.Types.ObjectId(targetAstrologerId),
      isPublic: true,
      isVerified: true
    }).select('astrologerId clientId rating reviewText createdAt isPublic isVerified');
    
    console.log(`Found ${filteredReviews.length} reviews after applying filters`);

    res.json({
      success: true,
      debug: {
        targetAstrologerId,
        totalReviewsInDB: allReviews.length,
        reviewsForUser: userReviews.length,
        reviewsAfterFilters: filteredReviews.length,
        sampleReviews: allReviews.slice(0, 5),
        userReviews: userReviews.slice(0, 5),
        filteredReviews: filteredReviews.slice(0, 5)
      }
    });

  } catch (error) {
    console.error('Error in debug:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to debug database',
      error: error.message
    });
  }
});

module.exports = router;
