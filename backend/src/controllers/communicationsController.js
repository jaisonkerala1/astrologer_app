const DirectConversation = require('../models/DirectConversation');
const DirectMessage = require('../models/DirectMessage');
const Call = require('../models/Call');
 
function toInt(value, fallback) {
  const n = parseInt(value, 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}
 
function getUnreadFor(conv, participantId) {
  try {
    if (!conv || !conv.unreadCount) return 0;
    // unreadCount is a Mongoose Map
    const v = typeof conv.unreadCount.get === 'function' ? conv.unreadCount.get(String(participantId)) : conv.unreadCount[String(participantId)];
    return Number.isFinite(v) ? v : (v ? Number(v) : 0);
  } catch (_) {
    return 0;
  }
}
 
function buildAdminSupportItem(astrologerId, conv) {
  const conversationId = `admin_${astrologerId}`;
  const lastAt = conv?.lastMessageAt || conv?.updatedAt || new Date();
  const preview = conv?.lastMessage || `Welcome! We're here to help you 24/7`;
  const unread = conv ? getUnreadFor(conv, astrologerId) : 0;
  const lastSenderId = conv?.lastMessageSenderId ? String(conv.lastMessageSenderId) : null;
 
  return {
    id: conv?._id?.toString?.() || conversationId,
    type: 'message',
    contactName: 'Admin Support',
    contactId: 'admin',
    contactType: 'admin',
    avatar: '',
    timestamp: lastAt instanceof Date ? lastAt.toISOString() : new Date(lastAt).toISOString(),
    preview,
    unreadCount: unread,
    isOnline: true,
    status: lastSenderId === String(astrologerId) ? 'sent' : 'received',
    conversationId,
  };
}
 
function buildConversationItem(astrologerId, conv) {
  const meId = String(astrologerId);
  const me = conv.participants?.find((p) => String(p.id) === meId && String(p.type) === 'astrologer');
  if (!me) return null;

  // Find "other" participant (admin/user/other astrologer)
  const other = conv.participants?.find((p) => !(String(p.id) === meId && String(p.type) === 'astrologer'));
  if (!other) return null;

  // Guard: never return self-contact items
  if (String(other.id) === meId && String(other.type) === 'astrologer') return null;

  const otherType = String(other.type || '').toLowerCase();
  if (otherType === 'admin') {
    return buildAdminSupportItem(astrologerId, conv);
  }

  const lastAt = conv.lastMessageAt || conv.updatedAt || new Date();
  const unread = getUnreadFor(conv, astrologerId);
  const lastSenderId = conv.lastMessageSenderId ? String(conv.lastMessageSenderId) : null;

  return {
    id: conv._id?.toString?.() || conv.conversationId,
    type: 'message',
    contactName: other.name || (otherType === 'astrologer' ? 'Astrologer' : 'User'),
    contactId: String(other.id || ''),
    contactType: otherType || 'user',
    avatar: other.avatar || '',
    timestamp: lastAt instanceof Date ? lastAt.toISOString() : new Date(lastAt).toISOString(),
    preview: conv.lastMessage || '',
    unreadCount: unread,
    isOnline: false,
    status: lastSenderId === String(astrologerId) ? 'sent' : 'received',
    conversationId: conv.conversationId,
  };
}

/**
 * Build CommunicationItem from Call document
 * Supports both admin-to-astrologer and user-to-astrologer calls
 */
function buildCallItem(astrologerId, call) {
  const astrologerIdStr = String(astrologerId);
  const isCaller = String(call.callerId) === astrologerIdStr && String(call.callerType) === 'astrologer';
  const isRecipient = String(call.recipientId) === astrologerIdStr && String(call.recipientType) === 'astrologer';
  
  // Guard: only process calls where astrologer is involved
  if (!isCaller && !isRecipient) return null;
  
  // Determine contact info (the other party - admin or user)
  const contact = isCaller 
    ? { 
        id: call.recipientId, 
        type: call.recipientType, 
        name: call.recipientName || (call.recipientType === 'admin' ? 'Admin Support' : 'User'),
        avatar: call.recipientAvatar || ''
      }
    : { 
        id: call.callerId, 
        type: call.callerType, 
        name: call.callerName || (call.callerType === 'admin' ? 'Admin Support' : 'User'),
        avatar: call.callerAvatar || ''
      };
  
  // Map call status to CommunicationStatus
  // Frontend expects: 'sent', 'received', 'missed', 'incoming', 'outgoing'
  let status = 'received'; // default
  if (call.status === 'missed') {
    status = 'missed';
  } else if (call.status === 'rejected' || call.status === 'cancelled') {
    status = 'missed'; // Frontend doesn't have 'rejected', use 'missed'
  } else if (call.status === 'ended') {
    // Check endReason to determine if completed
    if (call.endReason === 'completed' && call.duration > 0) {
      // Completed call: 'incoming' if astrologer was recipient, 'outgoing' if caller
      status = isRecipient ? 'incoming' : 'outgoing';
    } else {
      // Cancelled or other reasons
      status = 'missed';
    }
  } else if (call.status === 'failed') {
    status = 'missed';
  }
  
  // Format duration (MM:SS)
  let duration = null;
  if (call.duration && call.duration > 0) {
    const minutes = Math.floor(call.duration / 60);
    const seconds = call.duration % 60;
    duration = `${minutes}:${String(seconds).padStart(2, '0')}`;
  }
  
  // Determine call type
  const callType = call.callType === 'voice' ? 'voiceCall' : 'videoCall';
  
  // Use startedAt or createdAt for timestamp
  const timestamp = call.startedAt || call.createdAt || new Date();
  
  // Build preview text
  const preview = `${call.callType === 'video' ? 'Video' : 'Voice'} call`;
  
  return {
    id: call._id?.toString?.() || `call_${Date.now()}`,
    type: callType,
    contactName: contact.name,
    contactId: contact.id,
    contactType: contact.type,
    avatar: contact.avatar,
    timestamp: timestamp instanceof Date ? timestamp.toISOString() : new Date(timestamp).toISOString(),
    preview: preview,
    unreadCount: 0, // Calls don't have unread count
    isOnline: false,
    status: status,
    duration: duration,
    chargedAmount: 0, // Add billing logic if needed
    conversationId: null, // Optional: can link to conversation if needed
  };
}
 
// GET /api/communications/:astrologerId?page=1&limit=50
async function getAllCommunications(req, res) {
  try {
    const astrologerId = String(req.params.astrologerId || '');
    if (!astrologerId) {
      return res.status(400).json({ success: false, message: 'Astrologer ID is required' });
    }

    const page = toInt(req.query.page, 1);
    const limit = toInt(req.query.limit, 50);
    const skip = (page - 1) * limit;

    // Query more items from each source to ensure we get the most recent across both
    // Then merge, sort, and paginate
    const queryLimit = limit * 2;

    // Get conversations (messages)
    const convs = await DirectConversation.find({
      isActive: true,
      participants: { $elemMatch: { id: astrologerId, type: 'astrologer' } },
    })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .limit(queryLimit)
      .lean({ virtuals: false });

    const items = [];

    // Always include Admin Support (even if conversation not created yet)
    const adminConversationId = `admin_${astrologerId}`;
    const adminConv = convs.find((c) => String(c.conversationId) === adminConversationId) || null;
    items.push(buildAdminSupportItem(astrologerId, adminConv));

    // Add conversation items (messages)
    for (const conv of convs) {
      // Skip admin convo because we already included it as the dedicated Admin Support item
      if (String(conv.conversationId) === adminConversationId) continue;

      const item = buildConversationItem(astrologerId, conv);
      if (item) items.push(item);
    }

    // Get calls where astrologer is involved (both admin-to-astrologer and user-to-astrologer)
    // Only include completed calls (ended, missed, rejected, cancelled)
    // Wrap in try-catch to ensure messages are returned even if calls query fails
    try {
      const calls = await Call.find({
        $or: [
          { callerId: astrologerId, callerType: 'astrologer' },
          { recipientId: astrologerId, recipientType: 'astrologer' }
        ],
        status: { $in: ['ended', 'missed', 'rejected', 'cancelled', 'failed'] }
      })
        .sort({ startedAt: -1, createdAt: -1 })
        .limit(queryLimit)
        .lean();

      // Convert calls to CommunicationItems
      for (const call of calls) {
        const callItem = buildCallItem(astrologerId, call);
        if (callItem) items.push(callItem);
      }
    } catch (callError) {
      // Log error but don't fail the entire request - messages are more important
      console.error('⚠️ [COMM] Failed to load calls (messages will still be returned):', callError.message);
    }

    // Sort all items by timestamp (newest first)
    items.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

    // Apply pagination after merging
    const paginatedItems = items.slice(skip, skip + limit);

    // Debug logging
    console.log(`📊 [COMM] getAllCommunications: ${items.length} total items (${items.filter(i => i.type === 'message').length} messages, ${items.filter(i => i.type === 'voiceCall' || i.type === 'videoCall').length} calls), returning ${paginatedItems.length} items for page ${page}`);

    return res.status(200).json({ success: true, data: paginatedItems });
  } catch (error) {
    console.error('❌ [COMM] getAllCommunications failed:', error);
    return res.status(500).json({ success: false, message: 'Failed to load communications' });
  }
}
 
// GET /api/communications/:astrologerId/unread-counts
async function getUnreadCounts(req, res) {
  try {
    const astrologerId = String(req.params.astrologerId || '');
    if (!astrologerId) {
      return res.status(400).json({ success: false, message: 'Astrologer ID is required' });
    }

    // Get unread messages count
    const convs = await DirectConversation.find({
      isActive: true,
      participants: { $elemMatch: { id: astrologerId, type: 'astrologer' } },
    }).select({ unreadCount: 1 }).lean();

    const messages = convs.reduce((sum, c) => sum + getUnreadFor(c, astrologerId), 0);

    // Get actual missed calls count (only calls where astrologer was recipient and status is missed)
    const missedCalls = await Call.countDocuments({
      recipientId: astrologerId,
      recipientType: 'astrologer',
      status: 'missed',
      callType: 'voice'
    });

    const missedVideoCalls = await Call.countDocuments({
      recipientId: astrologerId,
      recipientType: 'astrologer',
      status: 'missed',
      callType: 'video'
    });

    return res.status(200).json({
      success: true,
      data: {
        messages,
        missedCalls,
        missedVideoCalls,
      },
    });
  } catch (error) {
    console.error('❌ [COMM] getUnreadCounts failed:', error);
    return res.status(500).json({ success: false, message: 'Failed to load unread counts' });
  }
}
 
// PATCH /api/communications/messages/:messageId/read
async function markMessageAsRead(req, res) {
  try {
    const messageId = String(req.params.messageId || '');
    if (!messageId) {
      return res.status(400).json({ success: false, message: 'Message ID is required' });
    }
 
    const msg = await DirectMessage.findById(messageId);
    if (!msg) return res.status(404).json({ success: false, message: 'Message not found' });
 
    if (msg.status !== 'read') {
      msg.status = 'read';
      msg.readAt = new Date();
      await msg.save();
    }
 
    // Best-effort: clear unread for recipient in the conversation
    try {
      const key = String(msg.recipientId);
      await DirectConversation.updateOne(
        { conversationId: msg.conversationId },
        { $set: { [`unreadCount.${key}`]: 0 } }
      );
    } catch (_) {}
 
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('❌ [COMM] markMessageAsRead failed:', error);
    return res.status(500).json({ success: false, message: 'Failed to mark message as read' });
  }
}
 
// PATCH /api/communications/:astrologerId/messages/mark-all-read
async function markAllMessagesAsRead(req, res) {
  try {
    const astrologerId = String(req.params.astrologerId || '');
    if (!astrologerId) {
      return res.status(400).json({ success: false, message: 'Astrologer ID is required' });
    }
 
    await DirectMessage.updateMany(
      { recipientId: astrologerId, recipientType: 'astrologer', status: { $ne: 'read' } },
      { $set: { status: 'read', readAt: new Date() } }
    );
 
    await DirectConversation.updateMany(
      { participants: { $elemMatch: { id: astrologerId, type: 'astrologer' } } },
      { $set: { [`unreadCount.${astrologerId}`]: 0 } }
    );
 
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('❌ [COMM] markAllMessagesAsRead failed:', error);
    return res.status(500).json({ success: false, message: 'Failed to mark all messages as read' });
  }
}
 
// PATCH /api/communications/:astrologerId/calls/clear-missed
async function clearMissedCalls(req, res) {
  try {
    const astrologerId = String(req.params.astrologerId || '');
    if (!astrologerId) {
      return res.status(400).json({ success: false, message: 'Astrologer ID is required' });
    }

    // Update missed calls to 'ended' with endReason 'cancelled' so they won't be counted as missed
    // This preserves call history while clearing the missed status
    await Call.updateMany(
      {
        recipientId: astrologerId,
        recipientType: 'astrologer',
        status: 'missed'
      },
      {
        $set: {
          status: 'ended',
          endReason: 'cancelled',
          endedAt: new Date()
        }
      }
    );

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('❌ [COMM] clearMissedCalls failed:', error);
    return res.status(500).json({ success: false, message: 'Failed to clear missed calls' });
  }
}
 
module.exports = {
  getAllCommunications,
  getUnreadCounts,
  markMessageAsRead,
  markAllMessagesAsRead,
  clearMissedCalls,
};

