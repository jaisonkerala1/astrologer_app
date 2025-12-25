/**
 * Socket.IO Main Setup
 * Initializes Socket.IO server with all handlers
 */

console.log('📦 [SOCKET.IO] Loading socket.io module...');
const { Server } = require('socket.io');
console.log('📦 [SOCKET.IO] Loading socketAuth...');
const { socketAuth, optionalSocketAuth } = require('./socketAuth');
console.log('📦 [SOCKET.IO] Loading liveHandler...');
const initLiveHandler = require('./handlers/liveHandler');
console.log('📦 [SOCKET.IO] Loading discussionHandler...');
const { initDiscussionHandler } = require('./handlers/discussionHandler');
console.log('📦 [SOCKET.IO] Loading serviceRequestHandler...');
const { initServiceRequestHandler } = require('./handlers/serviceRequestHandler');
console.log('📦 [SOCKET.IO] Loading directMessageHandler...');
const directMessageHandler = require('./handlers/directMessageHandler');
console.log('📦 [SOCKET.IO] Loading callHandler...');
const callHandler = require('./handlers/callHandler');
console.log('📦 [SOCKET.IO] Loading supportTicketHandler...');
const {
  initSupportTicketHandler,
  broadcastTicketMessage,
  broadcastTicketStatusChange,
  broadcastTicketAssigned,
  broadcastNewTicket,
  broadcastTicketPriorityChange,
} = require('./handlers/supportTicketHandler');
console.log('📦 [SOCKET.IO] Loading roomManager...');
const roomManager = require('./roomManager');
console.log('📦 [SOCKET.IO] Loading EVENTS...');
const EVENTS = require('./events');
console.log('✅ [SOCKET.IO] All modules loaded successfully');

/**
 * Initialize Socket.IO with HTTP server
 */
function initSocketIO(httpServer) {
  console.log('🔧 [SOCKET.IO] Creating Server instance...');
  const io = new Server(httpServer, {
    cors: {
      origin: function(origin, callback) {
        // Allow all origins for mobile apps
        callback(null, true);
      },
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    // Use polling first, then upgrade to websocket if available
    // This ensures Railway's proxy doesn't block initial connections
    transports: ['polling', 'websocket'],
    // Allow upgrades for better performance once connected
    allowUpgrades: true,
    // Increase max HTTP buffer size for Railway
    maxHttpBufferSize: 1e8,
    // Add path for explicit routing
    path: '/socket.io/',
  });

  console.log('🔌 [SOCKET.IO] Initializing...');

  // Apply authentication middleware
  console.log('🔧 [SOCKET.IO] Applying auth middleware...');
  io.use(optionalSocketAuth);

  // Connection handler
  console.log('🔧 [SOCKET.IO] Setting up connection handler...');
  io.on(EVENTS.CONNECTION, (socket) => {
    console.log(`🔌 [SOCKET] ✅ New connection established: ${socket.user?.name || 'Unknown'} (${socket.id})`);
    console.log(`🔌 [SOCKET] User type: ${socket.userType || 'unknown'}, User ID: ${socket.userId || 'unknown'}`);

    // Auto-join user to their personal room for notifications
    const userId = socket.userId || socket.user?._id || socket.user?.id;
    const userType = socket.userType || socket.user?.role || 'astrologer';
    
    if (userId) {
      // For admin, join to admin: room (no ID suffix needed)
      const personalRoom = userId === 'admin' 
        ? EVENTS.ROOM_PREFIX.ADMIN 
        : `${EVENTS.ROOM_PREFIX[userType.toUpperCase()]}${userId}`;
      socket.join(personalRoom);
      console.log(`✅ [SOCKET] Auto-joined ${userType} to personal room: ${personalRoom}`);
    }

    // Initialize feature handlers
    console.log('🔧 [SOCKET.IO] Initializing liveHandler...');
    initLiveHandler(io, socket);
    console.log('🔧 [SOCKET.IO] Initializing discussionHandler...');
    initDiscussionHandler(socket, io, roomManager);
    console.log('🔧 [SOCKET.IO] Initializing serviceRequestHandler...');
    initServiceRequestHandler(socket, io, roomManager);
    console.log('🔧 [SOCKET.IO] Initializing directMessageHandler...');
    directMessageHandler(io, socket);
    console.log('🔧 [SOCKET.IO] Initializing callHandler...');
    callHandler(io, socket);
    console.log('🔧 [SOCKET.IO] Initializing supportTicketHandler...');
    initSupportTicketHandler(io, socket);

    // Send connection success
    socket.emit('connected', {
      socketId: socket.id,
      user: socket.user,
      timestamp: Date.now(),
    });

    // Handle errors
    socket.on(EVENTS.ERROR, (error) => {
      console.error(`❌ [SOCKET] Error from ${socket.id}:`, error);
    });
  });

  // Stats endpoint for debugging
  io.on('connection', (socket) => {
    socket.on('get_stats', () => {
      if (socket.user && !socket.user.isAnonymous) {
        socket.emit('stats', roomManager.getStats());
      }
    });
  });

  console.log('✅ [SOCKET.IO] Initialized successfully');

  return io;
}

module.exports = {
  initSocketIO,
  roomManager,
  EVENTS,
  // Export support ticket broadcast functions for use in HTTP routes
  broadcastTicketMessage,
  broadcastTicketStatusChange,
  broadcastTicketAssigned,
  broadcastNewTicket,
  broadcastTicketPriorityChange,
};

