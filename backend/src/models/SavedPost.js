const mongoose = require('mongoose');

const savedPostSchema = new mongoose.Schema({
  // Discussion reference
  discussionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Discussion',
    required: true,
    index: true
  },
  
  // User information (can be astrologer or end-user)
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  userType: {
    type: String,
    enum: ['astrologer', 'user'],
    required: true,
    index: true
  },
  
  // Metadata
  savedAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  
  // Optional: Collections/folders for organizing saved posts
  collection: {
    type: String,
    default: 'default',
    trim: true
  },
  
  // Optional: Personal notes
  notes: {
    type: String,
    maxlength: [500, 'Notes cannot exceed 500 characters'],
    default: null
  }
}, {
  timestamps: false, // We're using savedAt instead
  collection: 'saved_posts'
});

// Compound indexes for better query performance
savedPostSchema.index({ userId: 1, userType: 1, savedAt: -1 });
savedPostSchema.index({ discussionId: 1, userId: 1, userType: 1 }, { unique: true });
savedPostSchema.index({ userId: 1, userType: 1, collection: 1 });

// Static method to toggle save
savedPostSchema.statics.toggleSave = async function(discussionId, userId, userType, collection = 'default') {
  try {
    // Check if already saved
    const existingSave = await this.findOne({
      discussionId,
      userId,
      userType
    });
    
    if (existingSave) {
      // Unsave - remove the save
      await existingSave.deleteOne();
      
      // Update save count on discussion
      const Discussion = mongoose.model('Discussion');
      await Discussion.findByIdAndUpdate(
        discussionId,
        { $inc: { saveCount: -1 } }
      );
      
      return { action: 'unsaved', saved: false };
    } else {
      // Save - create new save
      const newSave = await this.create({
        discussionId,
        userId,
        userType,
        collection,
        savedAt: new Date()
      });
      
      // Update save count on discussion
      const Discussion = mongoose.model('Discussion');
      await Discussion.findByIdAndUpdate(
        discussionId,
        { $inc: { saveCount: 1 } }
      );
      
      return { action: 'saved', saved: true, savedPost: newSave };
    }
  } catch (error) {
    console.error('Error toggling save:', error);
    throw error;
  }
};

// Static method to check if user has saved
savedPostSchema.statics.hasUserSaved = async function(discussionId, userId, userType) {
  const save = await this.findOne({
    discussionId,
    userId,
    userType
  });
  return !!save;
};

// Static method to get user's saved posts
savedPostSchema.statics.getUserSavedPosts = async function(userId, userType, options = {}) {
  const {
    collection = null,
    limit = 20,
    skip = 0,
    sortBy = 'savedAt',
    sortOrder = -1
  } = options;
  
  const query = { userId, userType };
  if (collection) {
    query.collection = collection;
  }
  
  return await this.find(query)
    .populate('discussionId')
    .sort({ [sortBy]: sortOrder })
    .limit(limit)
    .skip(skip);
};

// Static method to get collections
savedPostSchema.statics.getUserCollections = async function(userId, userType) {
  return await this.distinct('collection', { userId, userType });
};

// Static method to move to collection
savedPostSchema.methods.moveToCollection = async function(newCollection) {
  this.collection = newCollection;
  return this.save();
};

// Static method to add notes
savedPostSchema.methods.addNotes = async function(notes) {
  this.notes = notes;
  return this.save();
};

module.exports = mongoose.model('SavedPost', savedPostSchema);

