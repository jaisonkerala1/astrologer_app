const mongoose = require('mongoose');
const Review = require('../models/Review');

// Mock client data (in real app, these would be actual User records)
const mockClients = [
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123456'),
    name: 'Sarah Johnson',
    profilePicture: '',
    phone: '+1234567890'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123457'),
    name: 'Michael Chen',
    profilePicture: '',
    phone: '+1234567891'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123458'),
    name: 'Emily Rodriguez',
    profilePicture: '',
    phone: '+1234567892'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123459'),
    name: 'David Kim',
    profilePicture: '',
    phone: '+1234567893'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123460'),
    name: 'Lisa Thompson',
    profilePicture: '',
    phone: '+1234567894'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123461'),
    name: 'James Wilson',
    profilePicture: '',
    phone: '+1234567895'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123462'),
    name: 'Maria Garcia',
    profilePicture: '',
    phone: '+1234567896'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123463'),
    name: 'Robert Brown',
    profilePicture: '',
    phone: '+1234567897'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123464'),
    name: 'Jennifer Davis',
    profilePicture: '',
    phone: '+1234567898'
  },
  {
    _id: new mongoose.Types.ObjectId('64a123456789abcdef123465'),
    name: 'Christopher Miller',
    profilePicture: '',
    phone: '+1234567899'
  }
];

// Function to seed reviews for a specific astrologer
const seedReviewsForAstrologer = async (astrologerId) => {
  const reviewsData = [
    {
      clientId: mockClients[0]._id,
      astrologerId: astrologerId,
      rating: 5,
      reviewText: 'Amazing consultation! The astrologer was very insightful and helped me understand my situation better. Highly recommended!',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
    },
    {
      clientId: mockClients[1]._id,
      astrologerId: astrologerId,
      rating: 4,
      reviewText: 'Good session, got some valuable insights. The astrologer was professional and answered all my questions.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you for your feedback, Michael! I\'m glad I could help you gain clarity.',
      repliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000) // 5 days ago
    },
    {
      clientId: mockClients[2]._id,
      astrologerId: astrologerId,
      rating: 5,
      reviewText: 'Exceptional service! The reading was spot on and the guidance provided was exactly what I needed.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days ago
    },
    {
      clientId: mockClients[3]._id,
      astrologerId: astrologerId,
      rating: 3,
      reviewText: 'The session was okay, but I expected more detailed explanations. Some points were unclear.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000) // 10 days ago
    },
    {
      clientId: mockClients[4]._id,
      astrologerId: astrologerId,
      rating: 5,
      reviewText: 'Outstanding consultation! The astrologer was very knowledgeable and provided clear guidance. Will definitely book again.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you so much, Lisa! I look forward to our next session.',
      repliedAt: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000) // 12 days ago
    },
    {
      clientId: mockClients[5]._id,
      astrologerId: astrologerId,
      rating: 4,
      reviewText: 'Good experience overall. The astrologer was patient and explained things well.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000) // 15 days ago
    },
    {
      clientId: mockClients[6]._id,
      astrologerId: astrologerId,
      rating: 5,
      reviewText: 'Incredible accuracy in predictions! The astrologer understood my concerns perfectly and provided practical solutions.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'I\'m happy I could help guide you, Maria. Wishing you all the best!',
      repliedAt: new Date(Date.now() - 17 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000) // 18 days ago
    },
    {
      clientId: mockClients[7]._id,
      astrologerId: astrologerId,
      rating: 4,
      reviewText: 'Very insightful session. The astrologer helped me understand my career path better.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000) // 20 days ago
    },
    {
      clientId: mockClients[8]._id,
      astrologerId: astrologerId,
      rating: 5,
      reviewText: 'Absolutely wonderful! The guidance I received has been life-changing. Thank you so much!',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: null,
      repliedAt: null,
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000) // 25 days ago
    },
    {
      clientId: mockClients[9]._id,
      astrologerId: astrologerId,
      rating: 4,
      reviewText: 'Great consultation with helpful advice. The astrologer was very professional and knowledgeable.',
      sessionId: new mongoose.Types.ObjectId(),
      astrologerReply: 'Thank you for your kind words, Christopher! Best wishes to you.',
      repliedAt: new Date(Date.now() - 27 * 24 * 60 * 60 * 1000),
      isPublic: true,
      isVerified: true,
      createdAt: new Date(Date.now() - 28 * 24 * 60 * 60 * 1000) // 28 days ago
    }
  ];

  try {
    // Clear existing reviews for this astrologer
    await Review.deleteMany({ astrologerId: astrologerId });
    
    // Insert new reviews
    const createdReviews = await Review.insertMany(reviewsData);
    
    console.log(`✅ Successfully seeded ${createdReviews.length} reviews for astrologer ${astrologerId}`);
    return createdReviews;
  } catch (error) {
    console.error('❌ Error seeding reviews:', error);
    throw error;
  }
};

module.exports = {
  seedReviewsForAstrologer,
  mockClients
};
