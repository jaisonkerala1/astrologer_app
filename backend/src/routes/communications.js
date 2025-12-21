const express = require('express');
const router = express.Router();
 
const communicationsController = require('../controllers/communicationsController');
 
// Communications list (messages/calls/video) for astrologer
router.get('/:astrologerId', communicationsController.getAllCommunications);
router.get('/:astrologerId/unread-counts', communicationsController.getUnreadCounts);
 
// Mark message(s) read (client uses these endpoints)
router.patch('/messages/:messageId/read', communicationsController.markMessageAsRead);
router.patch('/:astrologerId/messages/mark-all-read', communicationsController.markAllMessagesAsRead);
router.patch('/:astrologerId/calls/clear-missed', communicationsController.clearMissedCalls);
 
module.exports = router;

