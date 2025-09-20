const mongoose = require('mongoose');
const { seedReviewsForAstrologer } = require('./seedReviews');

// Connect to MongoDB and seed reviews for your astrologer
const seedReviewsForUser = async () => {
  try {
    // Your astrologer ID from the logs
    const astrologerId = '68ccff521b39ed18eb9eaff3';
    
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/astrologer_app');
    console.log('✅ Connected to MongoDB');
    
    console.log(`🌱 Seeding reviews for astrologer: ${astrologerId}`);
    const createdReviews = await seedReviewsForAstrologer(astrologerId);
    
    console.log(`✅ Successfully created ${createdReviews.length} reviews!`);
    console.log('📊 Review distribution:');
    
    const ratings = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    createdReviews.forEach(review => {
      ratings[review.rating]++;
    });
    
    Object.entries(ratings).forEach(([rating, count]) => {
      console.log(`   ${rating} stars: ${count} reviews`);
    });
    
    const withReplies = createdReviews.filter(r => r.astrologerReply).length;
    const needingReplies = createdReviews.length - withReplies;
    
    console.log(`📝 Replied to: ${withReplies} reviews`);
    console.log(`⏳ Needing replies: ${needingReplies} reviews`);
    
  } catch (error) {
    console.error('❌ Error seeding reviews:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Disconnected from MongoDB');
    process.exit(0);
  }
};

// Run if called directly
if (require.main === module) {
  seedReviewsForUser();
}

module.exports = { seedReviewsForUser };
