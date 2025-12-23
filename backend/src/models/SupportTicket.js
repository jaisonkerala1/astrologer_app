const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema(
  {
    ticketNumber: {
      type: String,
      unique: true,
      // IMPORTANT:
      // ticketNumber is generated automatically in a pre('validate') hook.
      // It must NOT fail required validation before hooks run.
      required: false,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      required: true,
      maxlength: 2000,
    },
    category: {
      type: String,
      required: true,
      enum: [
        'Account Issues',
        'Calendar Problems',
        'Consultation Issues',
        'Payment Problems',
        'Technical Support',
        'Feature Request',
        'Bug Report',
        'Other',
      ],
      index: true,
    },
    priority: {
      type: String,
      required: true,
      enum: ['Low', 'Medium', 'High', 'Urgent'],
      default: 'Medium',
      index: true,
    },
    status: {
      type: String,
      required: true,
      enum: ['open', 'in_progress', 'waiting_for_user', 'closed'],
      default: 'open',
      index: true,
    },

    // User info (astrologer who created the ticket)
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Astrologer',
      required: true,
      index: true,
    },
    userType: {
      type: String,
      default: 'astrologer',
      enum: ['astrologer', 'user'],
    },
    userName: {
      type: String,
      required: true,
    },
    userEmail: {
      type: String,
      required: true,
    },
    userPhone: {
      type: String,
    },

    // Admin assignment
    assignedTo: {
      type: String, // Admin ID (from admin auth)
      ref: 'Admin',
      index: true,
    },
    assignedToName: {
      type: String,
    },
    assignedAt: {
      type: Date,
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

    // Timestamps
    closedAt: {
      type: Date,
    },
    firstResponseAt: {
      type: Date,
    },
    resolvedAt: {
      type: Date,
    },

    // Metrics
    responseTime: {
      type: Number, // Minutes to first admin response
    },
    resolutionTime: {
      type: Number, // Minutes to resolution
    },
    messagesCount: {
      type: Number,
      default: 0,
    },

    // Tags
    tags: [String],

    // Internal notes (admin only)
    internalNotes: {
      type: String,
      maxlength: 5000,
    },

    // User satisfaction rating (after ticket closed)
    userRating: {
      type: Number,
      min: 1,
      max: 5,
    },
    userFeedback: {
      type: String,
      maxlength: 1000,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for efficient queries
supportTicketSchema.index({ userId: 1, status: 1 });
supportTicketSchema.index({ assignedTo: 1, status: 1 });
supportTicketSchema.index({ createdAt: -1 });
supportTicketSchema.index({ priority: -1, createdAt: -1 });
// ticketNumber already has `unique: true` which creates an index; avoid duplicate index warnings.

// Generate ticket number BEFORE validation so required checks don't fail.
supportTicketSchema.pre('validate', async function (next) {
  if (this.isNew && !this.ticketNumber) {
    const date = new Date();
    const dateStr = date.toISOString().split('T')[0].replace(/-/g, '');
    
    // Find the last ticket number for today
    const lastTicket = await this.constructor
      .findOne({
        ticketNumber: new RegExp(`^TKT-${dateStr}-`),
      })
      .sort({ ticketNumber: -1 });

    let counter = 1;
    if (lastTicket && lastTicket.ticketNumber) {
      const lastCounter = parseInt(lastTicket.ticketNumber.split('-')[2]);
      counter = lastCounter + 1;
    }

    this.ticketNumber = `TKT-${dateStr}-${String(counter).padStart(5, '0')}`;
  }
  next();
});

// Update messagesCount when messages are added
supportTicketSchema.methods.incrementMessageCount = async function () {
  this.messagesCount += 1;
  await this.save();
};

// Calculate response time when admin first replies
supportTicketSchema.methods.setFirstResponse = async function () {
  if (!this.firstResponseAt) {
    this.firstResponseAt = new Date();
    const diffMinutes = Math.round(
      (this.firstResponseAt - this.createdAt) / (1000 * 60)
    );
    this.responseTime = diffMinutes;
    await this.save();
  }
};

// Calculate resolution time when ticket is closed
supportTicketSchema.methods.setResolved = async function () {
  if (!this.resolvedAt) {
    this.resolvedAt = new Date();
    const diffMinutes = Math.round(
      (this.resolvedAt - this.createdAt) / (1000 * 60)
    );
    this.resolutionTime = diffMinutes;
    this.status = 'closed';
    this.closedAt = new Date();
    await this.save();
  }
};

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
