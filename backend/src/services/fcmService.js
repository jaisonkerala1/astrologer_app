const { messaging } = require('../config/firebase');
const mongoose = require('mongoose');

class FcmService {
  /**
   * Send FCM notification to user
   * @param {String} userId - User ID
   * @param {String} userType - 'astrologer' or 'user'
   * @param {Object} notification - Notification data
   */
  static async sendNotification(userId, userType, notification) {
    try {
      // Check if FCM is initialized
      if (!messaging) {
        console.log('⚠️ [FCM] Firebase messaging not initialized, skipping notification');
        return { success: false, reason: 'fcm_not_initialized' };
      }

      // Admin is a web dashboard user (not a Mongo ObjectId) → don't attempt FCM
      if (userType === 'admin' || userId === 'admin') {
        return { success: false, reason: 'skip_admin' };
      }

      // Only support these user types for FCM right now
      if (userType !== 'astrologer' && userType !== 'user') {
        return { success: false, reason: 'unsupported_user_type' };
      }

      // Avoid CastError spam when userId isn't a valid ObjectId
      if (!mongoose.isValidObjectId(userId)) {
        console.log(`⚠️ [FCM] Invalid userId for FCM (${userType}): ${userId}`);
        return { success: false, reason: 'invalid_user_id' };
      }

      // Get user's FCM tokens
      const Model = userType === 'astrologer' 
        ? require('../models/Astrologer')
        : require('../models/User');
      
      const user = await Model.findById(userId).select('fcmTokens name');
      if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
        console.log(`⚠️ [FCM] No tokens found for ${userType}: ${userId} (${user?.name || 'unknown'})`);
        return { success: false, reason: 'no_tokens' };
      }
      
      const tokens = user.fcmTokens.map(t => t.token);
      
      // Construct FCM message
      // For calls, send data-only (no notification payload) to avoid duplicate notifications
      const isCallNotification = notification.channelId === 'calls';
      
      const message = {
        data: notification.data || {},
        tokens: tokens,
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };
      
      // Only add notification payload for non-call notifications (messages)
      if (!isCallNotification) {
        message.notification = {
          title: notification.title,
          body: notification.body,
        };
        message.android.notification = {
          sound: 'default',
          channelId: notification.channelId || 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        };
      } else {
        // For calls, just send high-priority data (Flutter will show custom notification)
        console.log(`📞 [FCM] Sending data-only call notification (no auto-notification)`);
      }
      
      // Send to multiple devices
      const response = await messaging.sendEachForMulticast(message);
      
      console.log(`✅ [FCM] Sent to ${userType} ${user.name}: ${response.successCount} success, ${response.failureCount} failed`);
      
      // Remove invalid tokens
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`⚠️ [FCM] Failed to send to token ${idx}: ${resp.error?.message}`);
            invalidTokens.push(tokens[idx]);
          }
        });
        
        if (invalidTokens.length > 0) {
          await Model.findByIdAndUpdate(userId, {
            $pull: { fcmTokens: { token: { $in: invalidTokens } } },
          });
          console.log(`🗑️ [FCM] Removed ${invalidTokens.length} invalid tokens for ${user.name}`);
        }
      }
      
      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error('❌ [FCM] Send notification error:', error);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * Send incoming call notification
   */
  static async sendCallNotification(recipientId, recipientType, callData) {
    const callTypeDisplay = callData.callType === 'video' ? 'Video' : 'Voice';
    
    return this.sendNotification(recipientId, recipientType, {
      title: `Incoming ${callTypeDisplay} Call`,
      body: `${callData.callerName} is calling...`,
      channelId: 'calls',
      data: {
        type: callData.callType === 'video' ? 'video_call' : 'call',
        callId: callData.callId || '',
        callerId: callData.callerId || '',
        callerName: callData.callerName || '',
        callerType: callData.callerType || '',
        callType: callData.callType || 'voice',
        channelName: callData.channelName || '',
        agoraToken: callData.token || '',
        agoraAppId: process.env.AGORA_APP_ID || '',
        timestamp: new Date().toISOString(),
      },
    });
  }
  
  /**
   * Send new message notification
   */
  static async sendMessageNotification(recipientId, recipientType, messageData) {
    return this.sendNotification(recipientId, recipientType, {
      title: messageData.senderName || 'New Message',
      body: messageData.content || '',
      channelId: 'messages',
      data: {
        type: 'message',
        conversationId: messageData.conversationId || '',
        senderId: messageData.senderId || '',
        senderName: messageData.senderName || '',
        senderType: messageData.senderType || '',
        content: messageData.content || '',
        timestamp: new Date().toISOString(),
      },
    });
  }
}

module.exports = FcmService;




