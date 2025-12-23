const express = require('express');
const router = express.Router();
const SupportTicket = require('../models/SupportTicket');
const TicketMessage = require('../models/TicketMessage');
const Astrologer = require('../models/Astrologer');
const adminAuth = require('../middleware/adminAuth');

// ============================================================================
// ADMIN TICKET MANAGEMENT ROUTES
// ============================================================================

/**
 * @route   GET /api/admin/support/tickets
 * @desc    Get all support tickets (with filters)
 * @access  Private (Admin only)
 */
router.get('/tickets', adminAuth, async (req, res) => {
  try {
    const {
      status,
      priority,
      category,
      assignedTo,
      search,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    // Build filter
    const filter = {};
    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (category) filter.category = category;
    
    // assignedTo=me means assigned to current admin
    if (assignedTo === 'me') {
      filter.assignedTo = req.userId; // Admin ID from adminAuth
    } else if (assignedTo) {
      filter.assignedTo = assignedTo;
    }

    // Search in title, description, ticketNumber
    if (search) {
      filter.$or = [
        { title: new RegExp(search, 'i') },
        { description: new RegExp(search, 'i') },
        { ticketNumber: new RegExp(search, 'i') },
        { userName: new RegExp(search, 'i') },
      ];
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

    // Get statistics
    const [
      totalTickets,
      openTickets,
      inProgressTickets,
      closedToday,
      avgResponseTime,
      avgResolutionTime,
      priorityStats,
      categoryStats,
    ] = await Promise.all([
      SupportTicket.countDocuments({}),
      SupportTicket.countDocuments({ status: 'open' }),
      SupportTicket.countDocuments({ status: 'in_progress' }),
      SupportTicket.countDocuments({
        closedAt: {
          $gte: new Date(new Date().setHours(0, 0, 0, 0)),
        },
      }),
      SupportTicket.aggregate([
        { $match: { responseTime: { $exists: true } } },
        { $group: { _id: null, avg: { $avg: '$responseTime' } } },
      ]),
      SupportTicket.aggregate([
        { $match: { resolutionTime: { $exists: true } } },
        { $group: { _id: null, avg: { $avg: '$resolutionTime' } } },
      ]),
      SupportTicket.aggregate([
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]),
      SupportTicket.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } },
      ]),
    ]);

    // Format stats
    const byPriority = {};
    priorityStats.forEach((p) => {
      byPriority[p._id] = p.count;
    });

    const byCategory = {};
    categoryStats.forEach((c) => {
      byCategory[c._id] = c.count;
    });

    res.json({
      success: true,
      data: {
        tickets: tickets.map((t) => ({ ...t, id: t._id })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalItems: totalCount,
          itemsPerPage: parseInt(limit),
        },
        stats: {
          totalTickets,
          openTickets,
          inProgressTickets,
          closedToday,
          avgResponseTime: avgResponseTime[0]?.avg || 0,
          avgResolutionTime: avgResolutionTime[0]?.avg || 0,
          byPriority,
          byCategory,
        },
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error fetching tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tickets',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/support/tickets/:ticketId
 * @desc    Get ticket details (admin view - includes internal notes)
 * @access  Private (Admin only)
 */
router.get('/tickets/:ticketId', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticket = await SupportTicket.findById(ticketId).lean();

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Get ALL messages (including internal notes)
    const messages = await TicketMessage.find({ ticketId: ticket._id })
      .sort({ createdAt: 1 })
      .lean();

    // Get user's ticket history
    const userHistory = await SupportTicket.aggregate([
      { $match: { userId: ticket.userId } },
      {
        $group: {
          _id: null,
          totalTickets: { $sum: 1 },
          closedTickets: {
            $sum: { $cond: [{ $eq: ['$status', 'closed'] }, 1, 0] },
          },
          avgRating: { $avg: '$userRating' },
        },
      },
    ]);

    res.json({
      success: true,
      data: {
        ...ticket,
        id: ticket._id,
        messages: messages.map((msg) => ({ ...msg, id: msg._id })),
        userHistory: userHistory[0] || {
          totalTickets: 1,
          closedTickets: 0,
          avgRating: null,
        },
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error fetching ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch ticket',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/admin/support/tickets/:ticketId/assign
 * @desc    Assign ticket to admin
 * @access  Private (Admin only)
 */
router.patch('/tickets/:ticketId/assign', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { assignedTo, assignedToName } = req.body;

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Update assignment
    ticket.assignedTo = assignedTo || null;
    ticket.assignedToName = assignedToName || null;
    ticket.assignedAt = assignedTo ? new Date() : null;
    
    // If assigning for first time, change status to in_progress
    if (assignedTo && ticket.status === 'open') {
      ticket.status = 'in_progress';
    }

    await ticket.save();

    // Create system message
    const messageText = assignedTo
      ? `Ticket assigned to ${assignedToName || 'admin'}`
      : 'Ticket unassigned';

    const systemMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: req.userId,
      senderName: 'System',
      senderType: 'system',
      message: messageText,
      isSystemMessage: true,
    });
    await systemMessage.save();

    console.log(`✅ [ADMIN-SUPPORT] Ticket ${ticket.ticketNumber} assigned to ${assignedToName}`);

    // TODO: Notify user and assigned admin

    res.json({
      success: true,
      message: 'Ticket assignment updated',
      data: {
        ticketId: ticket._id,
        assignedTo: ticket.assignedTo,
        assignedToName: ticket.assignedToName,
        assignedAt: ticket.assignedAt,
        status: ticket.status,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error assigning ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign ticket',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/admin/support/tickets/:ticketId/status
 * @desc    Update ticket status
 * @access  Private (Admin only)
 */
router.patch('/tickets/:ticketId/status', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status, internalNote } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    const oldStatus = ticket.status;
    ticket.status = status;

    // If closing ticket, set resolution time
    if (status === 'closed' && oldStatus !== 'closed') {
      await ticket.setResolved();
    }

    await ticket.save();

    // Create system message
    const systemMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: req.userId,
      senderName: 'System',
      senderType: 'system',
      message: `Status changed from ${oldStatus} to ${status}`,
      isSystemMessage: true,
    });
    await systemMessage.save();

    // Add internal note if provided
    if (internalNote) {
      ticket.internalNotes = (ticket.internalNotes || '') + `\n[${new Date().toISOString()}] ${internalNote}`;
      await ticket.save();
    }

    console.log(`✅ [ADMIN-SUPPORT] Ticket ${ticket.ticketNumber} status: ${oldStatus} → ${status}`);

    res.json({
      success: true,
      message: 'Ticket status updated',
      data: {
        ticketId: ticket._id,
        status: ticket.status,
        updatedAt: ticket.updatedAt,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error updating status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update status',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/admin/support/tickets/:ticketId/priority
 * @desc    Update ticket priority
 * @access  Private (Admin only)
 */
router.patch('/tickets/:ticketId/priority', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { priority } = req.body;

    if (!priority) {
      return res.status(400).json({
        success: false,
        message: 'Priority is required',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    const oldPriority = ticket.priority;
    ticket.priority = priority;
    await ticket.save();

    // Create system message
    const systemMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: req.userId,
      senderName: 'System',
      senderType: 'system',
      message: `Priority changed from ${oldPriority} to ${priority}`,
      isSystemMessage: true,
    });
    await systemMessage.save();

    console.log(`✅ [ADMIN-SUPPORT] Ticket ${ticket.ticketNumber} priority: ${oldPriority} → ${priority}`);

    res.json({
      success: true,
      message: 'Ticket priority updated',
      data: {
        ticketId: ticket._id,
        priority: ticket.priority,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error updating priority:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update priority',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/admin/support/tickets/:ticketId/messages
 * @desc    Add admin reply to ticket
 * @access  Private (Admin only)
 */
router.post('/tickets/:ticketId/messages', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message, isInternal = false, attachments } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message is required',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    // Get admin name (from token or request)
    const adminName = req.userName || 'Admin Support';

    // Create message
    const ticketMessage = new TicketMessage({
      ticketId: ticket._id,
      senderId: req.userId,
      senderName: adminName,
      senderType: 'admin',
      senderEmail: req.userEmail || 'admin@support.com',
      message: message.trim(),
      attachments: attachments || [],
      isInternal,
      isSystemMessage: false,
    });

    await ticketMessage.save();

    // Update ticket
    await ticket.incrementMessageCount();
    
    // Set first response time if this is first admin reply
    if (!isInternal) {
      await ticket.setFirstResponse();
      
      // Change status to waiting_for_user if admin replied
      if (ticket.status === 'open' || ticket.status === 'in_progress') {
        ticket.status = 'waiting_for_user';
      }
    }
    
    await ticket.save();

    console.log(`✅ [ADMIN-SUPPORT] ${isInternal ? 'Internal note' : 'Reply'} added to ${ticket.ticketNumber}`);

    // TODO: Notify user via FCM/Email if not internal

    res.status(201).json({
      success: true,
      message: isInternal ? 'Internal note added' : 'Reply sent successfully',
      data: {
        ...ticketMessage.toObject(),
        id: ticketMessage._id,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error adding message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add message',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/admin/support/tickets/:ticketId/internal-notes
 * @desc    Add internal note to ticket
 * @access  Private (Admin only)
 */
router.post('/tickets/:ticketId/internal-notes', adminAuth, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { note } = req.body;

    if (!note) {
      return res.status(400).json({
        success: false,
        message: 'Note is required',
      });
    }

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
      });
    }

    const adminName = req.userName || 'Admin';
    const timestamp = new Date().toISOString();
    const noteEntry = `\n[${timestamp}] ${adminName}: ${note}`;

    ticket.internalNotes = (ticket.internalNotes || '') + noteEntry;
    await ticket.save();

    console.log(`✅ [ADMIN-SUPPORT] Internal note added to ${ticket.ticketNumber}`);

    res.json({
      success: true,
      message: 'Internal note added',
      data: {
        ticketId: ticket._id,
        internalNotes: ticket.internalNotes,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error adding internal note:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add internal note',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/admin/support/tickets/bulk-action
 * @desc    Perform bulk action on multiple tickets
 * @access  Private (Admin only)
 */
router.post('/tickets/bulk-action', adminAuth, async (req, res) => {
  try {
    const { action, ticketIds, actionData } = req.body;

    if (!action || !ticketIds || ticketIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Action and ticketIds are required',
      });
    }

    let updateQuery = {};
    let successMessage = '';

    switch (action) {
      case 'assign':
        updateQuery = {
          assignedTo: actionData.assignedTo,
          assignedToName: actionData.assignedToName,
          assignedAt: new Date(),
        };
        successMessage = `${ticketIds.length} tickets assigned`;
        break;

      case 'update_status':
        updateQuery = { status: actionData.status };
        successMessage = `${ticketIds.length} tickets status updated`;
        break;

      case 'update_priority':
        updateQuery = { priority: actionData.priority };
        successMessage = `${ticketIds.length} tickets priority updated`;
        break;

      case 'close':
        updateQuery = {
          status: 'closed',
          closedAt: new Date(),
        };
        successMessage = `${ticketIds.length} tickets closed`;
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid action',
        });
    }

    const result = await SupportTicket.updateMany(
      { _id: { $in: ticketIds } },
      { $set: updateQuery }
    );

    console.log(`✅ [ADMIN-SUPPORT] Bulk action '${action}' on ${result.modifiedCount} tickets`);

    res.json({
      success: true,
      message: successMessage,
      data: {
        modifiedCount: result.modifiedCount,
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error in bulk action:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to perform bulk action',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/admin/support/stats
 * @desc    Get ticket statistics for dashboard
 * @access  Private (Admin only)
 */
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const { period = '7d' } = req.query;

    // Calculate date range
    let startDate = new Date();
    switch (period) {
      case '1d':
        startDate.setDate(startDate.getDate() - 1);
        break;
      case '7d':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(startDate.getDate() - 30);
        break;
      case '90d':
        startDate.setDate(startDate.getDate() - 90);
        break;
      case 'all':
        startDate = new Date(0); // Beginning of time
        break;
    }

    // Overview stats
    const [
      totalTickets,
      openTickets,
      avgResponseTime,
      avgResolutionTime,
      satisfactionRate,
    ] = await Promise.all([
      SupportTicket.countDocuments({ createdAt: { $gte: startDate } }),
      SupportTicket.countDocuments({ status: { $ne: 'closed' } }),
      SupportTicket.aggregate([
        {
          $match: {
            responseTime: { $exists: true },
            createdAt: { $gte: startDate },
          },
        },
        { $group: { _id: null, avg: { $avg: '$responseTime' } } },
      ]),
      SupportTicket.aggregate([
        {
          $match: {
            resolutionTime: { $exists: true },
            createdAt: { $gte: startDate },
          },
        },
        { $group: { _id: null, avg: { $avg: '$resolutionTime' } } },
      ]),
      SupportTicket.aggregate([
        {
          $match: {
            userRating: { $exists: true },
            createdAt: { $gte: startDate },
          },
        },
        { $group: { _id: null, avg: { $avg: '$userRating' } } },
      ]),
    ]);

    // Trends by day
    const trends = await SupportTicket.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
          },
          opened: { $sum: 1 },
          closed: {
            $sum: { $cond: [{ $eq: ['$status', 'closed'] }, 1, 0] },
          },
          avgResponseTime: { $avg: '$responseTime' },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Top categories
    const topCategories = await SupportTicket.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
    ]);

    // Top admins
    const topAdmins = await SupportTicket.aggregate([
      {
        $match: {
          assignedTo: { $exists: true, $ne: null },
          status: 'closed',
          createdAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: '$assignedTo',
          name: { $first: '$assignedToName' },
          ticketsResolved: { $sum: 1 },
          avgResolutionTime: { $avg: '$resolutionTime' },
        },
      },
      { $sort: { ticketsResolved: -1 } },
      { $limit: 10 },
    ]);

    res.json({
      success: true,
      data: {
        overview: {
          totalTickets,
          openTickets,
          avgResponseTime: Math.round(avgResponseTime[0]?.avg || 0),
          avgResolutionTime: Math.round(avgResolutionTime[0]?.avg || 0),
          satisfactionRate: satisfactionRate[0]?.avg || 0,
        },
        trends: trends.map((t) => ({
          date: t._id,
          opened: t.opened,
          closed: t.closed,
          avgResponseTime: Math.round(t.avgResponseTime || 0),
        })),
        topCategories: topCategories.map((c) => ({
          category: c._id,
          count: c.count,
        })),
        topAdmins: topAdmins.map((a) => ({
          adminId: a._id,
          name: a.name,
          ticketsResolved: a.ticketsResolved,
          avgResolutionTime: Math.round(a.avgResolutionTime || 0),
        })),
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-SUPPORT] Error fetching stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message,
    });
  }
});

module.exports = router;
