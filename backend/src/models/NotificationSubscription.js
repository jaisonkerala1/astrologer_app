const mongoose = require('mongoose');

const notificationSubscriptionSchema = new mongoose.Schema({
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
  
  // Notification settings
  notifyOnAllComments: {
    type: Boolean,
    default: false
  },
  notifyOnReplies: {
    type: Boolean,
    default: true // Always notify when someone replies to user's comment
  },
  notifyOnLikes: {
    type: Boolean,
    default: false
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Metadata
  subscribedAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  lastNotifiedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  collection: 'notification_subscriptions'
});

// Compound indexes for better query performance
notificationSubscriptionSchema.index({ discussionId: 1, userId: 1, userType: 1 }, { unique: true });
notificationSubscriptionSchema.index({ userId: 1, userType: 1, subscribedAt: -1 });
notificationSubscriptionSchema.index({ discussionId: 1, isActive: 1 });

// Static method to toggle subscription
notificationSubscriptionSchema.statics.toggleSubscription = async function(
  discussionId, 
  userId, 
  userType, 
  settings = {}
) {
  try {
    // Check if subscription already exists
    const existingSubscription = await this.findOne({
      discussionId,
      userId,
      userType
    });
    
    if (existingSubscription) {
      // Toggle active status or update settings
      if (Object.keys(settings).length > 0) {
        // Update settings
        Object.assign(existingSubscription, settings);
        await existingSubscription.save();
        return { action: 'updated', subscribed: existingSubscription.isActive, subscription: existingSubscription };
      } else {
        // Toggle active status
        existingSubscription.isActive = !existingSubscription.isActive;
        await existingSubscription.save();
        return { 
          action: existingSubscription.isActive ? 'subscribed' : 'unsubscribed', 
          subscribed: existingSubscription.isActive,
          subscription: existingSubscription 
        };
      }
    } else {
      // Create new subscription
      const defaultSettings = {
        notifyOnAllComments: settings.notifyOnAllComments !== undefined ? settings.notifyOnAllComments : true,
        notifyOnReplies: settings.notifyOnReplies !== undefined ? settings.notifyOnReplies : true,
        notifyOnLikes: settings.notifyOnLikes !== undefined ? settings.notifyOnLikes : false
      };
      
      const newSubscription = await this.create({
        discussionId,
        userId,
        userType,
        ...defaultSettings,
        isActive: true,
        subscribedAt: new Date()
      });
      
      return { action: 'subscribed', subscribed: true, subscription: newSubscription };
    }
  } catch (error) {
    console.error('Error toggling subscription:', error);
    throw error;
  }
};

// Static method to check if user is subscribed
notificationSubscriptionSchema.statics.isUserSubscribed = async function(discussionId, userId, userType) {
  const subscription = await this.findOne({
    discussionId,
    userId,
    userType,
    isActive: true
  });
  return !!subscription;
};

// Static method to get user's subscriptions
notificationSubscriptionSchema.statics.getUserSubscriptions = async function(userId, userType, limit = 50, skip = 0) {
  return await this.find({
    userId,
    userType,
    isActive: true
  })
  .populate('discussionId')
  .sort({ subscribedAt: -1 })
  .limit(limit)
  .skip(skip);
};

// Static method to get subscribers for a discussion
notificationSubscriptionSchema.statics.getDiscussionSubscribers = async function(discussionId, notificationType = 'all') {
  const query = {
    discussionId,
    isActive: true
  };
  
  // Filter by notification type
  if (notificationType === 'comments') {
    query.notifyOnAllComments = true;
  } else if (notificationType === 'replies') {
    query.notifyOnReplies = true;
  } else if (notificationType === 'likes') {
    query.notifyOnLikes = true;
  }
  
  return await this.find(query).select('userId userType notifyOnAllComments notifyOnReplies notifyOnLikes');
};

// Method to update last notified time
notificationSubscriptionSchema.methods.updateLastNotified = async function() {
  this.lastNotifiedAt = new Date();
  return this.save();
};

// Method to unsubscribe
notificationSubscriptionSchema.methods.unsubscribe = async function() {
  this.isActive = false;
  return this.save();
};

// Method to resubscribe
notificationSubscriptionSchema.methods.resubscribe = async function() {
  this.isActive = true;
  this.subscribedAt = new Date();
  return this.save();
};

// Static method to auto-subscribe discussion author
notificationSubscriptionSchema.statics.autoSubscribeAuthor = async function(discussionId, authorId, authorType) {
  try {
    const existingSubscription = await this.findOne({
      discussionId,
      userId: authorId,
      userType: authorType
    });
    
    if (!existingSubscription) {
      await this.create({
        discussionId,
        userId: authorId,
        userType: authorType,
        notifyOnAllComments: true,
        notifyOnReplies: true,
        notifyOnLikes: false,
        isActive: true
      });
    }
  } catch (error) {
    console.error('Error auto-subscribing author:', error);
  }
};

module.exports = mongoose.model('NotificationSubscription', notificationSubscriptionSchema);

