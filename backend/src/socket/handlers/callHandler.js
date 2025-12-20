/**
 * Call Handler
 * Handles voice and video calls between admin-astrologer and user-astrologer
 */

const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const Call = require('../../models/Call');
const DirectMessage = require('../../models/DirectMessage');
const { CALL, ROOM_PREFIX } = require('../events');
const FcmService = require('../../services/fcmService');

// Agora config (from .env)
const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

// Helpers
function getUserContext(socket, fallback = {}) {
  const user = socket.user || {};
  const isAnon = user.isAnonymous || user.role === 'guest';
  const type = isAnon ? 'admin' : (socket.userType || user.role || fallback.type || 'admin');
  const id = isAnon ? 'admin' : (socket.userId || user._id || user.id || fallback.id || 'admin');
  return {
    id,
    type,
    name: user.name || fallback.name || 'Admin',
    avatar: user.profilePicture || user.avatar || fallback.avatar || '',
  };
}

function roomFor(type, id) {
  if (!type) return null;
  const prefix = ROOM_PREFIX[type.toUpperCase()];
  if (!prefix) return null;
  
  // Special case: admin room is just 'admin:' with no ID suffix
  if (type.toLowerCase() === 'admin') {
    return prefix; // Returns 'admin:'
  }
  
  if (!id) return null;
  return `${prefix}${id}`;
}

/**
 * Generate Agora RTC token
 */
function generateAgoraToken(channelName, uid = 0) {
  if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
    console.error('❌ [AGORA] Missing credentials in .env');
    return null;
  }

  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
  
  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_APP_CERTIFICATE,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );
  
  return token;
}

/**
 * Create call log message in chat history
 */
async function createCallLogMessage(io, call, status, duration = 0) {
  try {
    // Determine direction from admin's perspective
    const isOutgoing = call.callerType === 'admin';
    
    // Create conversation ID (consistent format)
    const conversationId = call.callerType === 'admin' 
      ? `admin_${call.recipientId}`
      : `admin_${call.callerId}`;
    
    // Create call log message
    const callLogMessage = await DirectMessage.create({
      conversationId,
      senderId: call.callerId,
      senderType: call.callerType,
      senderName: call.callerName,
      senderAvatar: call.callerAvatar,
      recipientId: call.recipientId,
      recipientType: call.recipientType,
      content: `${call.callType === 'video' ? 'Video' : 'Voice'} call ${status}`,
      messageType: 'call_log',
      callType: call.callType,
      callStatus: status,
      callDuration: duration,
      callId: call._id,
      timestamp: new Date()
    });
    
    console.log(`📋 [CALL LOG] Created ${status} call log for conversation ${conversationId}`);
    
    // Emit to both parties so it appears in their chat history
    const callerRoom = roomFor(call.callerType, call.callerId);
    const recipientRoom = roomFor(call.recipientType, call.recipientId);
    
    const messagePayload = {
      ...callLogMessage.toObject(),
      _id: callLogMessage._id.toString(),
      callId: callLogMessage.callId?.toString()
    };
    
    if (callerRoom) {
      io.to(callerRoom).emit('dm:message_received', messagePayload);
    }
    if (recipientRoom) {
      io.to(recipientRoom).emit('dm:message_received', messagePayload);
    }
    
    console.log(`📤 [CALL LOG] Sent to rooms: ${callerRoom}, ${recipientRoom}`);
    
  } catch (error) {
    console.error('❌ [CALL LOG] Failed to create call log message:', error);
  }
}

module.exports = (io, socket) => {
  // Initiate a call
  socket.on(CALL.INITIATE, async (data) => {
    try {
      const {
        recipientId,
        recipientType,
        callType
      } = data;
      
      const callerCtx = getUserContext(socket);
      const callerId = callerCtx.id;
      const callerType = callerCtx.type;
      const callerName = callerCtx.name;
      const callerAvatar = callerCtx.avatar;
      
      console.log(`📞 [CALL] ${callerType}(${callerId}) initiating ${callType} call to ${recipientType}(${recipientId})`);
      
      // Auto-generate channel name if not provided
      const channelName = data.channelName || `call_${callerId}_${recipientId}_${Date.now()}`;
      
      // Generate Agora token
      const uid = 0; // 0 for auto-generated
      const agoraToken = generateAgoraToken(channelName, uid);
      
      if (!agoraToken) {
        socket.emit('error', { message: 'Failed to generate Agora token. Check server configuration.' });
        return;
      }
      
      // Create call record
      const call = await Call.create({
        callerId,
        callerType,
        callerName,
        callerAvatar,
        recipientId,
        recipientType,
        callType,
        channelName,
        agoraToken,
        agoraUid: uid,
        status: 'initiated',
        startedAt: new Date()
      });
      
      // Send token back to caller
      socket.emit(CALL.TOKEN, {
        callId: call._id.toString(),
        agoraToken,
        agoraAppId: AGORA_APP_ID,
        channelName,
        uid
      });
      
      console.log(`🔑 [CALL] Token sent to caller: ${callerId}`);
      
      // Update call status to ringing
      await Call.findByIdAndUpdate(call._id, {
        status: 'ringing',
        ringingAt: new Date()
      });
      
      // Notify recipient via Socket.IO (foreground)
      const recipientRoom = `${ROOM_PREFIX[recipientType.toUpperCase()]}${recipientId}`;
      io.to(recipientRoom).emit(CALL.INCOMING, {
        callId: call._id.toString(),
        callerId,
        callerName,
        callerType,
        callerAvatar,
        callType,
        agoraToken,
        agoraAppId: AGORA_APP_ID,
        channelName,
        uid
      });
      
      console.log(`🔔 [CALL] Incoming call notification sent to ${recipientType} room: ${recipientRoom}`);
      
      // Send FCM push notification (background/locked)
      FcmService.sendCallNotification(recipientId, recipientType, {
        callId: call._id.toString(),
        callerId,
        callerName,
        callerType,
        callType,
        token: agoraToken,
        channelName
      }).catch(err => {
        console.error('⚠️ [FCM] Failed to send call notification:', err.message);
      });
      
      // Auto-cancel if not answered in 60 seconds
      setTimeout(async () => {
        const callDoc = await Call.findById(call._id);
        if (callDoc && callDoc.status === 'ringing') {
          await Call.findByIdAndUpdate(call._id, {
            status: 'missed',
            endedAt: new Date(),
            endReason: 'timeout'
          });
          
          // Notify caller
          socket.emit(CALL.END, {
            callId: call._id.toString(),
            reason: 'missed',
            message: 'Call was not answered'
          });
          
          console.log(`⏰ [CALL] Call ${call._id} timed out (missed)`);
        }
      }, 60000);
      
    } catch (error) {
      console.error('❌ [CALL] Error initiating call:', error);
      socket.emit('error', { message: 'Failed to initiate call', error: error.message });
    }
  });

  // Accept a call
  socket.on(CALL.ACCEPT, async (data) => {
    try {
      const { callId, contactId } = data;
      
      console.log(`✅ [CALL] Call ${callId} accepted by ${socket.userId || socket.user?._id}`);
      
      // Update call status
      const call = await Call.findByIdAndUpdate(callId, {
        status: 'accepted',
        acceptedAt: new Date()
      }, { new: true });
      
      if (!call) {
        socket.emit('error', { message: 'Call not found' });
        return;
      }
      
      // Notify caller using roomFor (handles admin room correctly)
      const callerRoom = roomFor(call.callerType, call.callerId);
      
      if (callerRoom) {
        io.to(callerRoom).emit(CALL.ACCEPT, {
          callId: call._id.toString(),
          contactId: socket.userId || socket.user?._id,
          agoraToken: call.agoraToken,
          channelName: call.channelName,
          agoraAppId: AGORA_APP_ID
        });
        console.log(`✅ [CALL] Accept notification sent to ${call.callerType} room: ${callerRoom}`);
      } else {
        console.error(`❌ [CALL] Cannot determine caller room`);
      }
      
    } catch (error) {
      console.error('❌ [CALL] Error accepting call:', error);
      socket.emit('error', { message: 'Failed to accept call', error: error.message });
    }
  });

  // Reject a call
  socket.on(CALL.REJECT, async (data) => {
    try {
      let { callId, contactId, reason = 'declined' } = data;
      
      console.log(`❌ [CALL] Call ${callId} rejected by ${socket.userId || socket.user?._id}`);
      
      // Fetch call record to get caller info
      const call = await Call.findById(callId);
      if (!call) {
        console.error(`❌ [CALL] Cannot find call ${callId}`);
        socket.emit('error', { message: 'Call not found for rejection' });
        return;
      }
      
      // Derive contactId and type from call record (contactId is the CALLER who needs notification)
      const derivedContactId = call.callerId;
      const derivedContactType = call.callerType;
      
      console.log(`🔍 [CALL] Derived from call record - contactId: ${derivedContactId}, type: ${derivedContactType}`);
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'rejected',
        endedAt: new Date(),
        endReason: reason,
        endedBy: socket.userId || socket.user?._id,
        endedByType: socket.userType || socket.user?.role
      });
      
      // Create call log message (declined)
      await createCallLogMessage(io, call, 'declined', 0);
      
      // Notify caller using derived info
      const callerRoom = roomFor(derivedContactType, derivedContactId);
      
      if (callerRoom) {
        io.to(callerRoom).emit(CALL.REJECT, {
          callId,
          contactId: socket.userId || socket.user?._id,
          reason
        });
        console.log(`📴 [CALL] Reject notification sent to ${derivedContactType} room: ${callerRoom}`);
      } else {
        console.error(`❌ [CALL] Cannot determine caller room for type: ${derivedContactType}, id: ${derivedContactId}`);
      }
      
    } catch (error) {
      console.error('❌ [CALL] Error rejecting call:', error);
      socket.emit('error', { message: 'Failed to reject call', error: error.message });
    }
  });

  // Call connected
  socket.on(CALL.CONNECTED, async (data) => {
    try {
      const { callId, contactId } = data;
      
      // Fetch call record to determine the other party
      const call = await Call.findById(callId);
      if (!call) {
        console.error(`❌ [CALL] Cannot find call ${callId}`);
        return;
      }
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'connected',
        connectedAt: new Date()
      });
      
      console.log(`🔗 [CALL] Call ${callId} connected`);
      
      // Determine the OTHER party
      const currentUserId = socket.userId || socket.user?._id;
      const otherPartyId = (currentUserId === call.callerId) ? call.recipientId : call.callerId;
      const otherPartyType = (currentUserId === call.callerId) ? call.recipientType : call.callerType;
      
      // Notify other party
      const otherPartyRoom = roomFor(otherPartyType, otherPartyId);
      
      if (otherPartyRoom) {
        io.to(otherPartyRoom).emit(CALL.CONNECTED, {
          callId,
          contactId: currentUserId
        });
        console.log(`🔗 [CALL] Connected notification sent to ${otherPartyType} room: ${otherPartyRoom}`);
      }
      
    } catch (error) {
      console.error('❌ [CALL] Error updating call status:', error);
    }
  });

  // End call
  socket.on(CALL.END, async (data) => {
    try {
      const { callId, contactId, duration = 0, reason = 'completed' } = data;
      
      console.log(`📴 [CALL] Call ${callId} ended by ${socket.userId || socket.user?._id} (duration: ${duration}s)`);
      
      // Fetch call record to determine the other party
      const call = await Call.findById(callId);
      if (!call) {
        console.error(`❌ [CALL] Cannot find call ${callId}`);
        return;
      }
      
      // Update call record
      await Call.findByIdAndUpdate(callId, {
        status: 'ended',
        endedAt: new Date(),
        duration,
        endReason: reason,
        endedBy: socket.userId || socket.user?._id,
        endedByType: socket.userType || socket.user?.role
      });
      
      // Determine call status for log (completed if duration > 0, cancelled otherwise)
      const callStatus = duration > 0 ? 'completed' : 'cancelled';
      
      // Create call log message
      await createCallLogMessage(io, call, callStatus, duration);
      
      // Determine the OTHER party (the one who didn't end the call)
      const currentUserId = socket.userId || socket.user?._id;
      const otherPartyId = (currentUserId === call.callerId) ? call.recipientId : call.callerId;
      const otherPartyType = (currentUserId === call.callerId) ? call.recipientType : call.callerType;
      
      console.log(`🔍 [CALL] Notifying other party - type: ${otherPartyType}, id: ${otherPartyId}`);
      
      // Notify other party
      const otherPartyRoom = roomFor(otherPartyType, otherPartyId);
      
      if (otherPartyRoom) {
        io.to(otherPartyRoom).emit(CALL.END, {
          callId,
          duration,
          reason
        });
        console.log(`📴 [CALL] End notification sent to ${otherPartyType} room: ${otherPartyRoom}`);
      } else {
        console.error(`❌ [CALL] Cannot determine room for type: ${otherPartyType}, id: ${otherPartyId}`);
      }
      
      console.log(`✅ [CALL] Call ${callId} ended successfully`);
      
    } catch (error) {
      console.error('❌ [CALL] Error ending call:', error);
      socket.emit('error', { message: 'Failed to end call', error: error.message });
    }
  });

  // Request new token (for token refresh during long calls)
  socket.on(CALL.TOKEN, async (data) => {
    try {
      const { callId, channelName } = data;
      
      // Generate new token
      const uid = 0;
      const agoraToken = generateAgoraToken(channelName, uid);
      
      if (!agoraToken) {
        socket.emit('error', { message: 'Failed to generate token' });
        return;
      }
      
      socket.emit(CALL.TOKEN, {
        callId,
        agoraToken,
        agoraAppId: AGORA_APP_ID,
        channelName,
        uid
      });
      
      console.log(`🔑 [CALL] New token generated for call: ${callId}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error generating token:', error);
      socket.emit('error', { message: 'Failed to generate token', error: error.message });
    }
  });
};

