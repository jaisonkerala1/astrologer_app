/**
 * Room Manager
 * Centralized tracking of socket rooms and users
 */

class RoomManager {
  constructor() {
    // Map of roomId -> { type, users: Map(socketId -> userData), metadata }
    this.rooms = new Map();
    // Map of socketId -> Set of roomIds (for quick cleanup on disconnect)
    this.socketRooms = new Map();
  }

  /**
   * Create or get a room
   */
  getOrCreateRoom(roomId, type, metadata = {}) {
    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, {
        type,
        users: new Map(),
        metadata,
        createdAt: new Date(),
      });
      console.log(`📦 [ROOM] Created room: ${roomId} (${type})`);
    }
    return this.rooms.get(roomId);
  }

  /**
   * Add user to a room
   */
  joinRoom(socketId, roomId, userData) {
    const room = this.rooms.get(roomId);
    if (!room) {
      console.log(`⚠️ [ROOM] Room not found: ${roomId}`);
      return null;
    }

    // Add user to room
    room.users.set(socketId, {
      ...userData,
      joinedAt: new Date(),
    });

    // Track which rooms this socket is in
    if (!this.socketRooms.has(socketId)) {
      this.socketRooms.set(socketId, new Set());
    }
    this.socketRooms.get(socketId).add(roomId);

    console.log(`✅ [ROOM] User ${userData.name || socketId} joined ${roomId} (${room.users.size} users)`);
    
    return room;
  }

  /**
   * Remove user from a room
   */
  leaveRoom(socketId, roomId) {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const userData = room.users.get(socketId);
    room.users.delete(socketId);

    // Remove room from socket's room list
    const socketRoomSet = this.socketRooms.get(socketId);
    if (socketRoomSet) {
      socketRoomSet.delete(roomId);
    }

    console.log(`👋 [ROOM] User left ${roomId} (${room.users.size} users remaining)`);

    // Clean up empty rooms (except live rooms which should persist)
    if (room.users.size === 0 && room.type !== 'live') {
      this.rooms.delete(roomId);
      console.log(`🗑️ [ROOM] Deleted empty room: ${roomId}`);
    }

    return { room, userData };
  }

  /**
   * Remove user from all rooms (on disconnect)
   */
  leaveAllRooms(socketId) {
    const roomIds = this.socketRooms.get(socketId);
    const leftRooms = [];

    if (roomIds) {
      for (const roomId of roomIds) {
        const result = this.leaveRoom(socketId, roomId);
        if (result) {
          leftRooms.push({ roomId, ...result });
        }
      }
      this.socketRooms.delete(socketId);
    }

    return leftRooms;
  }

  /**
   * Get user count in a room
   */
  getRoomUserCount(roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.users.size : 0;
  }

  /**
   * Get all users in a room
   */
  getRoomUsers(roomId) {
    const room = this.rooms.get(roomId);
    if (!room) return [];
    
    return Array.from(room.users.values());
  }

  /**
   * Get room metadata
   */
  getRoomMetadata(roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.metadata : null;
  }

  /**
   * Update room metadata
   */
  updateRoomMetadata(roomId, metadata) {
    const room = this.rooms.get(roomId);
    if (room) {
      room.metadata = { ...room.metadata, ...metadata };
    }
  }

  /**
   * Check if user is in room
   */
  isUserInRoom(socketId, roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.users.has(socketId) : false;
  }

  /**
   * Get all rooms a socket is in
   */
  getSocketRooms(socketId) {
    return Array.from(this.socketRooms.get(socketId) || []);
  }

  /**
   * Delete a room
   */
  deleteRoom(roomId) {
    const room = this.rooms.get(roomId);
    if (room) {
      // Remove room from all sockets' room lists
      for (const socketId of room.users.keys()) {
        const socketRoomSet = this.socketRooms.get(socketId);
        if (socketRoomSet) {
          socketRoomSet.delete(roomId);
        }
      }
      this.rooms.delete(roomId);
      console.log(`🗑️ [ROOM] Deleted room: ${roomId}`);
      return true;
    }
    return false;
  }

  /**
   * Get stats for debugging
   */
  getStats() {
    return {
      totalRooms: this.rooms.size,
      totalConnections: this.socketRooms.size,
      rooms: Array.from(this.rooms.entries()).map(([id, room]) => ({
        id,
        type: room.type,
        userCount: room.users.size,
      })),
    };
  }
}

// Singleton instance
const roomManager = new RoomManager();

module.exports = roomManager;

