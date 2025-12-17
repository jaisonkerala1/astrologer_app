/**
 * Socket.IO Main Setup
 * Initializes Socket.IO server with all handlers
 */

const { Server } = require('socket.io');
const { socketAuth, optionalSocketAuth } = require('./socketAuth');
const initLiveHandler = require('./handlers/liveHandler');
const { initDiscussionHandler } = require('./handlers/discussionHandler');
const { initServiceRequestHandler } = require('./handlers/serviceRequestHandler');
const directMessageHandler = require('./handlers/directMessageHandler');
const callHandler = require('./handlers/callHandler');
const roomManager = require('./roomManager');
const EVENTS = require('./events');

/**
 * Initialize Socket.IO with HTTP server
 */
function initSocketIO(httpServer) {
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
    transports: ['websocket', 'polling'],
  });

  console.log('🔌 [SOCKET.IO] Initializing...');

  // Apply authentication middleware
  io.use(optionalSocketAuth);

  // Connection handler
  io.on(EVENTS.CONNECTION, (socket) => {
    console.log(`🔌 [SOCKET] New connection: ${socket.user.name} (${socket.id})`);

    // Initialize feature handlers
    initLiveHandler(io, socket);
    initDiscussionHandler(socket, io, roomManager);
    initServiceRequestHandler(socket, io, roomManager);
    directMessageHandler(io, socket);
    callHandler(io, socket);

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

module.exports = { initSocketIO, roomManager, EVENTS };

