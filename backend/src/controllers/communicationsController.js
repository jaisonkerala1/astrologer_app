const DirectConversation = require('../models/DirectConversation');
const DirectMessage = require('../models/DirectMessage');
 
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
 
    const convs = await DirectConversation.find({
      isActive: true,
      participants: { $elemMatch: { id: astrologerId, type: 'astrologer' } },
    })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean({ virtuals: false });
 
    const items = [];
 
    // Always include Admin Support (even if conversation not created yet)
    const adminConversationId = `admin_${astrologerId}`;
    const adminConv = convs.find((c) => String(c.conversationId) === adminConversationId) || null;
    items.push(buildAdminSupportItem(astrologerId, adminConv));
 
    for (const conv of convs) {
      // Skip admin convo because we already included it as the dedicated Admin Support item
      if (String(conv.conversationId) === adminConversationId) continue;
 
      const item = buildConversationItem(astrologerId, conv);
      if (item) items.push(item);
    }
 
    // Sort by timestamp desc for safety
    items.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
 
    return res.status(200).json({ success: true, data: items });
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
 
    const convs = await DirectConversation.find({
      isActive: true,
      participants: { $elemMatch: { id: astrologerId, type: 'astrologer' } },
    }).select({ unreadCount: 1 }).lean();
 
    const messages = convs.reduce((sum, c) => sum + getUnreadFor(c, astrologerId), 0);
 
    return res.status(200).json({
      success: true,
      data: {
        messages,
        missedCalls: 0,
        missedVideoCalls: 0,
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
async function clearMissedCalls(_req, res) {
  // Calls are handled elsewhere; keep endpoint for client compatibility.
  return res.status(200).json({ success: true });
}
 
module.exports = {
  getAllCommunications,
  getUnreadCounts,
  markMessageAsRead,
  markAllMessagesAsRead,
  clearMissedCalls,
};

