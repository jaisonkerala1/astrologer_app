const express = require('express');
const router = express.Router();
const SupportTicket = require('../models/SupportTicket');
const TicketMessage = require('../models/TicketMessage');
const Astrologer = require('../models/Astrologer');
const auth = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for ticket attachments
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/tickets';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'ticket-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|pdf|doc|docx|txt/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only images, PDFs, and documents are allowed'));
    }
  },
});

// ============================================================================
// USER TICKET ROUTES (Astrologer)
// ============================================================================

/**
 * @route   POST /api/support/tickets
 * @desc    Create a new support ticket
 * @access  Private (Astrologer)
 */
router.post('/tickets', auth, async (req, res) => {
  try {
    const { title, description, category, priority, attachments } = req.body;
    const astrologerId = String(req.user?.astrologerId || req.astrologerId || '');

    // Validate required fields
    if (!title || !description || !category) {
      return res.status(400).json({
        success: false,
        message: 'Title, description, and category are required',
      });
    }

    if (!astrologerId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - astrologerId missing from token',
      });
    }

    // Get astrologer details
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found',
      });
    }

    // Create ticket
    const ticket = new SupportTicket({
      title,
      description,
      category,
      priority: priority || 'Medium',
      status: 'open',
      userId: astrologerId,
      userType: 'astrologer',
      userName: astrologer.name,
      userEmail: astrologer.email,
      userPhone: astrologer.phone,
      attachments: attachments || [],
    });

    await ticket.save();

    console.log(`✅ [SUPPORT] New ticket created: ${ticket.ticketNumber} by ${astrologer.name}`);

    // TODO: Send FCM notification to admins
    // TODO: Send email notification to admins

    res.status(201).json({
      success: true,
      message: 'Support ticket created successfully',
      data: ticket,
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error creating ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create ticket',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/tickets
 * @desc    Get user's tickets
 * @access  Private (Astrologer)
 */
router.get('/tickets', auth, async (req, res) => {
  try {
    const astrologerId = String(req.user?.astrologerId || req.astrologerId || '');
    const { status, page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;

    if (!astrologerId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - astrologerId missing from token',
      });
    }

    const filter = { userId: astrologerId };
    if (status) {
      filter.status = status;
    }

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [tickets, totalCount] = await Promise.all([
      SupportTicket.find(filter)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      SupportTicket.countDocuments(filter),
    ]);

    // Get message count for each ticket
    const ticketIds = tickets.map((t) => t._id);
    const messageCounts = await TicketMessage.aggregate([
      { $match: { ticketId: { $in: ticketIds } } },
      { $group: { _id: '$ticketId', count: { $sum: 1 } } },
    ]);

    const messageCountMap = {};
    messageCounts.forEach((mc) => {
      messageCountMap[mc._id.toString()] = mc.count;
    });

    // Add message counts to tickets
    const ticketsWithCounts = tickets.map((ticket) => ({
      ...ticket,
      id: ticket._id,
      messagesCount: messageCountMap[ticket._id.toString()] || 0,
    }));

    // Get stats
    const [openCount, closedCount] = await Promise.all([
      SupportTicket.countDocuments({ userId: astrologerId, status: { $ne: 'closed' } }),
      SupportTicket.countDocuments({ userId: astrologerId, status: 'closed' }),
    ]);

    res.json({
      success: true,
      data: {
        tickets: ticketsWithCounts,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalItems: totalCount,
          itemsPerPage: parseInt(limit),
        },
        stats: {
          openTickets: openCount,
          closedTickets: closedCount,
        },
      },
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error fetching tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tickets',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/tickets/:ticketId
 * @desc    Get ticket details with messages
 * @access  Private (Astrologer - must own ticket)
 */
router.get('/tickets/:ticketId', auth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const astrologerId = String(req.user?.astrologerId || req.astrologerId || '');

    if (!astrologerId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - astrologerId missing from token',
      });
    }

    const ticket = await SupportTicket.findById(ticketId).lean();

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Check ownership
    if (ticket.userId.toString() !== astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden - You can only view your own tickets',
      });
    }

    // Get messages (exclude internal admin notes)
    const messages = await TicketMessage.find({
      ticketId: ticket._id,
      isInternal: false,
    })
      .sort({ createdAt: 1 })
      .lean();

    // Format response
    const response = {
      ...ticket,
      id: ticket._id,
      messages: messages.map((msg) => ({
        ...msg,
        id: msg._id,
      })),
    };

    res.json({
      success: true,
      data: response,
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error fetching ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch ticket',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/support/tickets/:ticketId/messages
 * @desc    Add message to ticket
 * @access  Private (Astrologer - must own ticket)
 */
router.post('/tickets/:ticketId/messages', auth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message, attachments } = req.body;
    const astrologerId = String(req.user?.astrologerId || req.astrologerId || '');

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message is required',
      });
    }

    if (!astrologerId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - astrologerId missing from token',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Check ownership
    if (ticket.userId.toString() !== astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden - You can only message your own tickets',
      });
    }

    // Check if ticket is closed
    if (ticket.status === 'closed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot add messages to closed ticket',
      });
    }

    // Get astrologer details
    const astrologer = await Astrologer.findById(astrologerId);

    // Create message
    const ticketMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: astrologerId,
      senderName: astrologer.name,
      senderType: 'user',
      senderEmail: astrologer.email,
      message: message.trim(),
      attachments: attachments || [],
      isInternal: false,
      isSystemMessage: false,
    });

    await ticketMessage.save();

    // Update ticket
    await ticket.incrementMessageCount();
    ticket.updatedAt = new Date();
    
    // If ticket was waiting for user response, change to in_progress
    if (ticket.status === 'waiting_for_user') {
      ticket.status = 'in_progress';
    }
    
    await ticket.save();

    console.log(`✅ [SUPPORT] Message added to ticket ${ticket.ticketNumber}`);

    // TODO: Notify assigned admin via Socket.IO
    // TODO: Send FCM/email notification to admin

    res.status(201).json({
      success: true,
      message: 'Message added successfully',
      data: {
        ...ticketMessage.toObject(),
        id: ticketMessage._id,
      },
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error adding message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add message',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/support/tickets/:ticketId/close
 * @desc    Close ticket (by user)
 * @access  Private (Astrologer - must own ticket)
 */
router.patch('/tickets/:ticketId/close', auth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const astrologerId = String(req.user?.astrologerId || req.astrologerId || '');

    if (!astrologerId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - astrologerId missing from token',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Check ownership
    if (ticket.userId.toString() !== astrologerId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden - You can only close your own tickets',
      });
    }

    // Close ticket
    await ticket.setResolved();

    // Add system message
    const systemMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: astrologerId,
      senderName: ticket.userName,
      senderType: 'system',
      message: 'Ticket closed by user',
      isSystemMessage: true,
    });
    await systemMessage.save();

    console.log(`✅ [SUPPORT] Ticket closed by user: ${ticket.ticketNumber}`);

    res.json({
      success: true,
      message: 'Ticket closed successfully',
      data: {
        ticketId: ticket._id,
        status: ticket.status,
        closedAt: ticket.closedAt,
      },
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error closing ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to close ticket',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/support/tickets/upload
 * @desc    Upload attachment for ticket
 * @access  Private (Astrologer)
 */
router.post('/tickets/upload', auth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded',
      });
    }

    const fileUrl = `/uploads/tickets/${req.file.filename}`;

    res.json({
      success: true,
      data: {
        url: fileUrl,
        filename: req.file.originalname,
        size: req.file.size,
      },
    });
  } catch (error) {
    console.error('❌ [SUPPORT] Error uploading file:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload file',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/categories
 * @desc    Get ticket categories and priority levels
 * @access  Public
 */
router.get('/categories', (req, res) => {
  res.json({
    success: true,
    data: {
      categories: [
        'Account Issues',
        'Calendar Problems',
        'Consultation Issues',
        'Payment Problems',
        'Technical Support',
        'Feature Request',
        'Bug Report',
        'Other',
      ],
      priorities: ['Low', 'Medium', 'High', 'Urgent'],
      statuses: ['open', 'in_progress', 'waiting_for_user', 'closed'],
    },
  });
});

module.exports = router;
