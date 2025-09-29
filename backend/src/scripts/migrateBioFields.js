const mongoose = require('mongoose');
const Astrologer = require('../models/Astrologer');

// Migration script to add bio fields to existing astrologers
const migrateBioFields = async () => {
  try {
    console.log('Starting bio fields migration...');
    
    // Find astrologers that don't have bio fields
    const astrologersWithoutBio = await Astrologer.find({
      $or: [
        { bio: { $exists: false } },
        { awards: { $exists: false } },
        { certificates: { $exists: false } }
      ]
    });

    console.log(`Found ${astrologersWithoutBio.length} astrologers without bio fields`);

    if (astrologersWithoutBio.length === 0) {
      console.log('All astrologers already have bio fields. Migration complete.');
      return;
    }

    // Update each astrologer with bio fields
    const updatePromises = astrologersWithoutBio.map(astrologer => {
      const updateData = {};
      
      if (!astrologer.bio) updateData.bio = '';
      if (!astrologer.awards) updateData.awards = '';
      if (!astrologer.certificates) updateData.certificates = '';
      
      return Astrologer.findByIdAndUpdate(
        astrologer._id,
        { $set: updateData },
        { new: true }
      );
    });

    await Promise.all(updatePromises);
    
    console.log(`Successfully migrated ${astrologersWithoutBio.length} astrologers with bio fields`);
    console.log('Migration completed successfully!');
    
  } catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
};

// Run migration if this file is executed directly
if (require.main === module) {
  mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/astrologer_app')
    .then(() => {
      console.log('Connected to MongoDB');
      return migrateBioFields();
    })
    .then(() => {
      console.log('Migration completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = migrateBioFields;
