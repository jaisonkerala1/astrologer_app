/**
 * Socket.IO Event Constants
 * Centralized event names for all real-time features
 */

module.exports = {
  // Connection events
  CONNECTION: 'connection',
  DISCONNECT: 'disconnect',
  ERROR: 'error',

  // Live Streaming Events
  LIVE: {
    JOIN: 'live:join',
    LEAVE: 'live:leave',
    VIEWER_COUNT: 'live:viewer_count',
    COMMENT: 'live:comment',
    GIFT: 'live:gift',
    REACTION: 'live:reaction',
    LIKE: 'live:like',              // NEW: User likes the stream
    UNLIKE: 'live:unlike',          // NEW: User unlikes the stream
    LIKE_COUNT: 'live:like_count',  // NEW: Broadcast like count updates
    END: 'live:end',
    VIEWER_JOINED: 'live:viewer_joined',
    VIEWER_LEFT: 'live:viewer_left',
  },

  // Chat Events
  CHAT: {
    JOIN: 'chat:join',
    LEAVE: 'chat:leave',
    MESSAGE: 'chat:message',
    TYPING: 'chat:typing',
    STOP_TYPING: 'chat:stop_typing',
    READ: 'chat:read',
    ONLINE: 'chat:online',
    OFFLINE: 'chat:offline',
  },

  // Discussion Events
  DISCUSSION: {
    JOIN: 'discussion:join',
    LEAVE: 'discussion:leave',
    COMMENT: 'discussion:comment',
    REPLY: 'discussion:reply',
    LIKE: 'discussion:like',
    UPDATE: 'discussion:update',
    DELETE: 'discussion:delete',
  },

  // Notification Events
  NOTIFICATION: {
    NEW: 'notification:new',
    READ: 'notification:read',
  },

  // Room prefixes
  ROOM_PREFIX: {
    LIVE: 'live:',
    CHAT: 'chat:',
    DISCUSSION: 'discussion:',
    USER: 'user:',
  },
};

