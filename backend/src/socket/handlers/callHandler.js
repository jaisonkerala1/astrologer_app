/**
 * Call Handler
 * Handles voice and video calls between admin-astrologer and user-astrologer
 */

const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const Call = require('../../models/Call');
const { CALL, ROOM_PREFIX } = require('../events');

// Agora config (from .env)
const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

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

module.exports = (io, socket) => {
  // Initiate a call
  socket.on(CALL.INITIATE, async (data) => {
    try {
      const {
        recipientId,
        recipientType,
        callType,
        channelName
      } = data;
      
      const callerId = socket.userId || socket.user?._id || socket.user?.id || 'admin';
      const callerType = socket.userType || socket.user?.role || 'astrologer';
      const callerName = socket.user?.name || socket.userName || 'Admin';
      const callerAvatar = socket.user?.profilePicture || socket.user?.avatar || socket.userAvatar || '';
      
      console.log(`📞 [CALL] ${callerType}(${callerId}) initiating ${callType} call to ${recipientType}(${recipientId})`);
      
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
      
      // Notify recipient
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
      
      console.log(`✅ [CALL] Call ${callId} accepted by ${socket.userId}`);
      
      // Update call status
      const call = await Call.findByIdAndUpdate(callId, {
        status: 'accepted',
        acceptedAt: new Date()
      }, { new: true });
      
      if (!call) {
        socket.emit('error', { message: 'Call not found' });
        return;
      }
      
      // Notify caller
      const callerRoom = contactId.startsWith('admin') 
        ? ROOM_PREFIX.ADMIN 
        : `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      
      io.to(callerRoom).emit(CALL.ACCEPT, {
        callId: call._id.toString(),
        contactId: socket.userId || socket.user?._id,
        agoraToken: call.agoraToken,
        channelName: call.channelName,
        agoraAppId: AGORA_APP_ID
      });
      
      console.log(`✅ [CALL] Accept notification sent to caller room: ${callerRoom}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error accepting call:', error);
      socket.emit('error', { message: 'Failed to accept call', error: error.message });
    }
  });

  // Reject a call
  socket.on(CALL.REJECT, async (data) => {
    try {
      const { callId, contactId, reason = 'declined' } = data;
      
      console.log(`❌ [CALL] Call ${callId} rejected by ${socket.userId}`);
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'rejected',
        endedAt: new Date(),
        endReason: reason,
        endedBy: socket.userId || socket.user?._id,
        endedByType: socket.userType || socket.user?.role
      });
      
      // Notify caller
      const callerRoom = contactId.startsWith('admin') 
        ? ROOM_PREFIX.ADMIN 
        : `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      
      io.to(callerRoom).emit(CALL.REJECT, {
        callId,
        contactId: socket.userId || socket.user?._id,
        reason
      });
      
      console.log(`📴 [CALL] Reject notification sent to caller`);
      
    } catch (error) {
      console.error('❌ [CALL] Error rejecting call:', error);
      socket.emit('error', { message: 'Failed to reject call', error: error.message });
    }
  });

  // Call connected
  socket.on(CALL.CONNECTED, async (data) => {
    try {
      const { callId, contactId } = data;
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'connected',
        connectedAt: new Date()
      });
      
      console.log(`🔗 [CALL] Call ${callId} connected`);
      
      // Notify other party
      const contactRoom = contactId.startsWith('admin') 
        ? ROOM_PREFIX.ADMIN 
        : `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      
      io.to(contactRoom).emit(CALL.CONNECTED, {
        callId,
        contactId: socket.userId || socket.user?._id
      });
      
    } catch (error) {
      console.error('❌ [CALL] Error updating call status:', error);
    }
  });

  // End call
  socket.on(CALL.END, async (data) => {
    try {
      const { callId, contactId, duration = 0, reason = 'completed' } = data;
      
      console.log(`📴 [CALL] Call ${callId} ended (duration: ${duration}s)`);
      
      // Update call record
      await Call.findByIdAndUpdate(callId, {
        status: 'ended',
        endedAt: new Date(),
        duration,
        endReason: reason,
        endedBy: socket.userId || socket.user?._id,
        endedByType: socket.userType || socket.user?.role
      });
      
      // Notify other party
      if (contactId) {
        const contactRoom = contactId.startsWith('admin') 
          ? ROOM_PREFIX.ADMIN 
          : `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
        
        io.to(contactRoom).emit(CALL.END, {
          callId,
          duration,
          reason
        });
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

