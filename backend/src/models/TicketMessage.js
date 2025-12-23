const mongoose = require('mongoose');

const ticketMessageSchema = new mongoose.Schema(
  {
    ticketId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'SupportTicket',
      required: true,
      index: true,
    },

    // Sender info
    senderId: {
      type: String, // Can be ObjectId or 'admin'
      required: true,
      index: true,
    },
    senderName: {
      type: String,
      required: true,
    },
    senderType: {
      type: String,
      required: true,
      enum: ['user', 'admin', 'system'],
      default: 'user',
    },
    senderEmail: {
      type: String,
    },

    // Message content
    message: {
      type: String,
      required: true,
      maxlength: 5000,
    },

    // Attachments
    attachments: [
      {
        url: String,
        filename: String,
        size: Number,
        uploadedAt: Date,
      },
    ],

    // Metadata
    isInternal: {
      type: Boolean,
      default: false, // Internal admin notes (not visible to user)
    },
    isSystemMessage: {
      type: Boolean,
      default: false, // Auto-generated messages (status changes, etc.)
    },

    // Read status
    readBy: [
      {
        userId: String,
        userType: String, // 'user' or 'admin'
        readAt: Date,
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Indexes
ticketMessageSchema.index({ ticketId: 1, createdAt: -1 });
ticketMessageSchema.index({ senderId: 1, createdAt: -1 });

module.exports = mongoose.model('TicketMessage', ticketMessageSchema);
