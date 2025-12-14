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
    LIKE: 'live:like',
    UNLIKE: 'live:unlike',
    LIKE_COUNT: 'live:like_count',
    END: 'live:end',
    VIEWER_JOINED: 'live:viewer_joined',
    VIEWER_LEFT: 'live:viewer_left',
    // Global events (broadcast to ALL connected users)
    STREAM_STARTED: 'live:stream_started',
    STREAM_ENDED: 'live:stream_ended',
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

