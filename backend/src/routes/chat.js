const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// Get all conversations for a user
router.get('/conversations/:userId', chatController.getConversations);

// Get active conversation for a user
router.get('/active/:userId', chatController.getActiveConversation);

// Create new conversation
router.post('/conversations', chatController.createConversation);

// Add message to conversation
router.post('/conversations/:conversationId/messages', chatController.addMessage);

// Update conversation settings
router.put('/conversations/:conversationId/settings', chatController.updateSettings);

// Clear conversation history for a user
router.delete('/history/:userId', chatController.clearHistory);

// Delete specific conversation
router.delete('/conversations/:conversationId', chatController.deleteConversation);

module.exports = router;


































