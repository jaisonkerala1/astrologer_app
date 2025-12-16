/**
 * Service Request Socket Handler
 * Handles real-time events for service requests (Heal tab)
 */

const EVENTS = require('../events');
const ServiceRequest = require('../../models/ServiceRequest');
const Service = require('../../models/Service');

/**
 * Initialize service request socket handlers
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 * @param {Object} roomManager - Room manager for tracking users in rooms
 */
function initServiceRequestHandler(socket, io, roomManager) {
  const user = socket.user;

  if (!user) {
    console.log('⚠️ [SERVICE_REQUEST] No user attached to socket');
    return;
  }

  // Auto-join astrologer's service request room on connection
  if (user.astrologerId) {
    const astrologerRoomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${user.astrologerId}`;
    socket.join(astrologerRoomId);
    roomManager.joinRoom(socket.id, astrologerRoomId, user);
    console.log(`✅ [SERVICE_REQUEST] ${user.name} auto-joined astrologer room: ${astrologerRoomId}`);
  }

  /**
   * Join astrologer's service request room (explicit join)
   * Event: service-request:join
   * Payload: { astrologerId }
   */
  socket.on(EVENTS.SERVICE_REQUEST.JOIN, async (data) => {
    try {
      const { astrologerId } = data;

      if (!astrologerId) {
        socket.emit(EVENTS.ERROR, { message: 'Astrologer ID is required' });
        return;
      }

      // Verify user has permission (must be the astrologer or admin)
      if (user.astrologerId !== astrologerId && !user.isAdmin) {
        socket.emit(EVENTS.ERROR, { message: 'Unauthorized to join this room' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;

      // Join the astrologer's room
      socket.join(roomId);
      roomManager.joinRoom(socket.id, roomId, user);

      console.log(`📥 [SERVICE_REQUEST] ${user.name} joined service request room for astrologer: ${astrologerId}`);

      // Acknowledge successful join
      socket.emit('service-request:joined', {
        astrologerId,
        roomId,
        message: 'Joined service request room'
      });

    } catch (error) {
      console.error('❌ [SERVICE_REQUEST] Join error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to join service request room' });
    }
  });

  /**
   * Leave astrologer's service request room
   * Event: service-request:leave
   * Payload: { astrologerId }
   */
  socket.on(EVENTS.SERVICE_REQUEST.LEAVE, async (data) => {
    try {
      const { astrologerId } = data;

      if (!astrologerId) {
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
      socket.leave(roomId);
      roomManager.leaveRoom(socket.id, roomId);

      console.log(`📤 [SERVICE_REQUEST] ${user.name} left service request room: ${astrologerId}`);

      socket.emit('service-request:left', {
        astrologerId,
        message: 'Left service request room'
      });

    } catch (error) {
      console.error('❌ [SERVICE_REQUEST] Leave error:', error);
    }
  });

  /**
   * Handle disconnect - cleanup service request rooms
   */
  socket.on('disconnect', () => {
    // Clean up all astrologer rooms for this socket
    socket.rooms.forEach((room) => {
      if (room.startsWith(EVENTS.ROOM_PREFIX.ASTROLOGER)) {
        roomManager.leaveRoom(socket.id, room);
      }
    });
  });
}

/**
 * Broadcast new service request to astrologer's room
 * Called from API routes
 * @param {Server} io - Socket.IO server instance
 * @param {String} astrologerId - Astrologer ID
 * @param {Object} request - Service request data
 */
function broadcastNewServiceRequest(io, astrologerId, request) {
  const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
  
  io.to(roomId).emit(EVENTS.SERVICE_REQUEST.NEW, {
    requestId: request._id?.toString() || request.id,
    customerName: request.customerName,
    customerPhone: request.customerPhone,
    serviceName: request.serviceName,
    serviceCategory: request.serviceCategory,
    requestedDate: request.requestedDate,
    requestedTime: request.requestedTime,
    status: request.status,
    price: request.price,
    specialInstructions: request.specialInstructions,
    createdAt: request.createdAt,
    isManual: request.isManual,
    source: request.source,
  });

  console.log(`📢 [SERVICE_REQUEST] Broadcast NEW request to astrologer ${astrologerId}`);
}

/**
 * Broadcast service request status update
 * Called from API routes
 * @param {Server} io - Socket.IO server instance
 * @param {String} astrologerId - Astrologer ID
 * @param {Object} request - Updated service request data
 */
function broadcastServiceRequestStatus(io, astrologerId, request) {
  const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
  
  io.to(roomId).emit(EVENTS.SERVICE_REQUEST.STATUS, {
    requestId: request._id?.toString() || request.id,
    status: request.status,
    statusDisplay: request.statusDisplay,
    startedAt: request.startedAt,
    completedAt: request.completedAt,
    cancelledAt: request.cancelledAt,
    confirmedAt: request.confirmedAt,
    updatedAt: request.updatedAt || new Date(),
  });

  console.log(`📢 [SERVICE_REQUEST] Broadcast STATUS update to astrologer ${astrologerId}: ${request.status}`);
}

/**
 * Broadcast service request notes update
 * Called from API routes
 * @param {Server} io - Socket.IO server instance
 * @param {String} astrologerId - Astrologer ID
 * @param {Object} request - Updated service request data
 */
function broadcastServiceRequestNotes(io, astrologerId, request) {
  const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
  
  io.to(roomId).emit(EVENTS.SERVICE_REQUEST.NOTES, {
    requestId: request._id?.toString() || request.id,
    notes: request.notes,
    updatedAt: request.updatedAt || new Date(),
  });

  console.log(`📢 [SERVICE_REQUEST] Broadcast NOTES update to astrologer ${astrologerId}`);
}

/**
 * Broadcast service request deletion
 * Called from API routes
 * @param {Server} io - Socket.IO server instance
 * @param {String} astrologerId - Astrologer ID
 * @param {String} requestId - Service request ID
 */
function broadcastServiceRequestDelete(io, astrologerId, requestId) {
  const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
  
  io.to(roomId).emit(EVENTS.SERVICE_REQUEST.DELETE, {
    requestId,
    deletedAt: new Date(),
  });

  console.log(`📢 [SERVICE_REQUEST] Broadcast DELETE to astrologer ${astrologerId}: ${requestId}`);
}

/**
 * Broadcast general service request update
 * Called from API routes
 * @param {Server} io - Socket.IO server instance
 * @param {String} astrologerId - Astrologer ID
 * @param {Object} request - Full updated service request data
 */
function broadcastServiceRequestUpdate(io, astrologerId, request) {
  const roomId = `${EVENTS.ROOM_PREFIX.ASTROLOGER}${astrologerId}`;
  
  io.to(roomId).emit(EVENTS.SERVICE_REQUEST.UPDATE, {
    requestId: request._id?.toString() || request.id,
    customerName: request.customerName,
    customerPhone: request.customerPhone,
    customerEmail: request.customerEmail,
    serviceName: request.serviceName,
    serviceCategory: request.serviceCategory,
    requestedDate: request.requestedDate,
    requestedTime: request.requestedTime,
    status: request.status,
    price: request.price,
    specialInstructions: request.specialInstructions,
    notes: request.notes,
    startedAt: request.startedAt,
    completedAt: request.completedAt,
    cancelledAt: request.cancelledAt,
    confirmedAt: request.confirmedAt,
    updatedAt: request.updatedAt || new Date(),
  });

  console.log(`📢 [SERVICE_REQUEST] Broadcast UPDATE to astrologer ${astrologerId}`);
}

module.exports = {
  initServiceRequestHandler,
  broadcastNewServiceRequest,
  broadcastServiceRequestStatus,
  broadcastServiceRequestNotes,
  broadcastServiceRequestDelete,
  broadcastServiceRequestUpdate,
};

