const SupportTicket = require('../models/SupportTicket');
const TicketMessage = require('../models/TicketMessage');
const Astrologer = require('../models/Astrologer');

/**
 * Support Ticket Socket.IO Handler
 * Handles real-time updates for support tickets
 */

function initSupportTicketHandler(io, socket) {
  console.log('🎫 [SUPPORT-SOCKET] Initializing support ticket handler for', socket.id);

  /**
   * Join a ticket room
   * User joins their own ticket, admins can join any ticket
   */
  socket.on('join_ticket', async (data) => {
    try {
      const { ticketId } = data;
      const userId = socket.userId; // From socketAuth
      const userType = socket.userType; // 'astrologer' or 'admin'

      console.log(`🎫 [SUPPORT-SOCKET] ${userType} ${userId} joining ticket room: ${ticketId}`);

      // Validate ticket exists
      const ticket = await SupportTicket.findById(ticketId);
      if (!ticket) {
        socket.emit('ticket:error', { message: 'Ticket not found' });
        return;
      }

      // Check authorization
      // User can only join their own tickets, admins can join any
      if (userType !== 'admin' && ticket.userId.toString() !== userId) {
        socket.emit('ticket:error', { message: 'Forbidden - Not your ticket' });
        return;
      }

      // Join room
      const roomName = `ticket:${ticketId}`;
      await socket.join(roomName);

      console.log(`✅ [SUPPORT-SOCKET] ${userType} ${userId} joined ticket room: ${roomName}`);

      // Send confirmation
      socket.emit('ticket:joined', {
        ticketId,
        roomName,
      });

      // Mark messages as read for this user
      await TicketMessage.updateMany(
        {
          ticketId,
          'readBy.userId': { $ne: userId },
        },
        {
          $addToSet: {
            readBy: {
              userId,
              userType,
              readAt: new Date(),
            },
          },
        }
      );

      // Notify others in the room about user activity
      socket.to(roomName).emit('ticket:user_active', {
        userId,
        userType,
        ticketId,
      });
    } catch (error) {
      console.error('❌ [SUPPORT-SOCKET] Error joining ticket:', error);
      socket.emit('ticket:error', { message: 'Failed to join ticket room' });
    }
  });

  /**
   * Leave a ticket room
   */
  socket.on('leave_ticket', async (data) => {
    try {
      const { ticketId } = data;
      const roomName = `ticket:${ticketId}`;

      await socket.leave(roomName);

      console.log(`👋 [SUPPORT-SOCKET] User ${socket.userId} left ticket room: ${roomName}`);

      socket.emit('ticket:left', { ticketId });
    } catch (error) {
      console.error('❌ [SUPPORT-SOCKET] Error leaving ticket:', error);
    }
  });

  /**
   * Send typing indicator
   */
  socket.on('ticket:typing', (data) => {
    try {
      const { ticketId, isTyping } = data;
      const roomName = `ticket:${ticketId}`;

      // Broadcast typing status to others in room
      socket.to(roomName).emit('ticket:typing', {
        ticketId,
        userId: socket.userId,
        userName: socket.userName || 'User',
        userType: socket.userType,
        isTyping,
      });
    } catch (error) {
      console.error('❌ [SUPPORT-SOCKET] Error in typing event:', error);
    }
  });

  /**
   * Admin joins ticket monitoring (for admin dashboard)
   * Admins can join a general room to get notified of all new tickets
   */
  socket.on('admin_join_ticket_monitor', async () => {
    try {
      if (socket.userType !== 'admin') {
        socket.emit('ticket:error', { message: 'Admin only' });
        return;
      }

      const adminRoom = 'admin:ticket_monitor';
      await socket.join(adminRoom);

      console.log(`✅ [SUPPORT-SOCKET] Admin ${socket.userId} joined ticket monitor room`);

      socket.emit('ticket:admin_monitor_joined', { room: adminRoom });
    } catch (error) {
      console.error('❌ [SUPPORT-SOCKET] Error joining admin monitor:', error);
    }
  });

  /**
   * Handle disconnect
   */
  socket.on('disconnect', () => {
    console.log(`🔌 [SUPPORT-SOCKET] User ${socket.userId} disconnected from support`);
  });
}

/**
 * Broadcast ticket events to specific rooms
 * These are called from HTTP routes
 */

/**
 * Broadcast new message to ticket room
 */
async function broadcastTicketMessage(io, ticketId, message) {
  try {
    const roomName = `ticket:${ticketId}`;

    io.to(roomName).emit('ticket:new_message', {
      ticketId,
      message: {
        ...message.toObject(),
        id: message._id,
      },
    });

    console.log(`📤 [SUPPORT-SOCKET] Broadcasted message to ticket room: ${roomName}`);

    // Also notify admin monitor room if message is from user
    if (message.senderType === 'user') {
      io.to('admin:ticket_monitor').emit('ticket:new_user_message', {
        ticketId,
        ticketNumber: message.ticketNumber,
        userName: message.senderName,
        preview: message.message.substring(0, 100),
      });
    }
  } catch (error) {
    console.error('❌ [SUPPORT-SOCKET] Error broadcasting message:', error);
  }
}

/**
 * Broadcast ticket status change
 */
async function broadcastTicketStatusChange(io, ticketId, statusUpdate) {
  try {
    const roomName = `ticket:${ticketId}`;

    io.to(roomName).emit('ticket:status_changed', {
      ticketId,
      ...statusUpdate,
    });

    console.log(`📤 [SUPPORT-SOCKET] Broadcasted status change to ticket room: ${roomName}`);
  } catch (error) {
    console.error('❌ [SUPPORT-SOCKET] Error broadcasting status change:', error);
  }
}

/**
 * Broadcast ticket assignment
 */
async function broadcastTicketAssigned(io, ticketId, assignmentData) {
  try {
    const roomName = `ticket:${ticketId}`;

    io.to(roomName).emit('ticket:assigned', {
      ticketId,
      ...assignmentData,
    });

    console.log(`📤 [SUPPORT-SOCKET] Broadcasted assignment to ticket room: ${roomName}`);

    // Notify assigned admin specifically
    if (assignmentData.assignedTo) {
      io.to(`admin:${assignmentData.assignedTo}`).emit('ticket:assigned_to_you', {
        ticketId,
        ticketNumber: assignmentData.ticketNumber,
        title: assignmentData.title,
      });
    }
  } catch (error) {
    console.error('❌ [SUPPORT-SOCKET] Error broadcasting assignment:', error);
  }
}

/**
 * Broadcast new ticket creation (to admin monitor)
 */
async function broadcastNewTicket(io, ticket) {
  try {
    io.to('admin:ticket_monitor').emit('ticket:new_ticket', {
      ticket: {
        ...ticket.toObject(),
        id: ticket._id,
      },
    });

    console.log(`📤 [SUPPORT-SOCKET] Broadcasted new ticket to admin monitor: ${ticket.ticketNumber}`);
  } catch (error) {
    console.error('❌ [SUPPORT-SOCKET] Error broadcasting new ticket:', error);
  }
}

/**
 * Broadcast ticket priority change
 */
async function broadcastTicketPriorityChange(io, ticketId, priorityData) {
  try {
    const roomName = `ticket:${ticketId}`;

    io.to(roomName).emit('ticket:priority_changed', {
      ticketId,
      ...priorityData,
    });

    console.log(`📤 [SUPPORT-SOCKET] Broadcasted priority change to ticket room: ${roomName}`);
  } catch (error) {
    console.error('❌ [SUPPORT-SOCKET] Error broadcasting priority change:', error);
  }
}

module.exports = {
  initSupportTicketHandler,
  broadcastTicketMessage,
  broadcastTicketStatusChange,
  broadcastTicketAssigned,
  broadcastNewTicket,
  broadcastTicketPriorityChange,
};
