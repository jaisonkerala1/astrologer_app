const Conversation = require('../models/Chat');

// Get all conversations for a user
const getConversations = async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    const conversations = await Conversation.find({ 
      userId: userId,
      isActive: true 
    }).sort({ updatedAt: -1 });

    res.status(200).json({
      success: true,
      data: conversations
    });
  } catch (error) {
    console.error('Error getting conversations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get conversations'
    });
  }
};

// Get active conversation for a user
const getActiveConversation = async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    const conversation = await Conversation.findOne({ 
      userId: userId,
      isActive: true 
    }).sort({ updatedAt: -1 });

    res.status(200).json({
      success: true,
      data: conversation
    });
  } catch (error) {
    console.error('Error getting active conversation:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get active conversation'
    });
  }
};

// Create new conversation
const createConversation = async (req, res) => {
  try {
    const { userId, title = 'New Chat with Loona' } = req.body;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    // Deactivate any existing active conversation
    await Conversation.updateMany(
      { userId: userId, isActive: true },
      { isActive: false }
    );

    const conversationId = Date.now().toString();
    const conversation = new Conversation({
      id: conversationId,
      userId: userId,
      title: title,
      messages: [],
      isActive: true,
    });

    await conversation.save();

    res.status(201).json({
      success: true,
      data: conversation
    });
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create conversation'
    });
  }
};

// Add message to conversation
const addMessage = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { message } = req.body;
    
    if (!conversationId || !message) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID and message are required'
      });
    }

    const conversation = await Conversation.findOne({ id: conversationId });
    
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    conversation.messages.push(message);
    conversation.updatedAt = new Date();
    
    await conversation.save();

    res.status(200).json({
      success: true,
      data: conversation
    });
  } catch (error) {
    console.error('Error adding message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add message'
    });
  }
};

// Update conversation settings
const updateSettings = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { settings } = req.body;
    
    if (!conversationId || !settings) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID and settings are required'
      });
    }

    const conversation = await Conversation.findOne({ id: conversationId });
    
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    conversation.chatSettings = { ...conversation.chatSettings, ...settings };
    conversation.updatedAt = new Date();
    
    await conversation.save();

    res.status(200).json({
      success: true,
      data: conversation
    });
  } catch (error) {
    console.error('Error updating settings:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update settings'
    });
  }
};

// Clear conversation history
const clearHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    // Deactivate all conversations for the user
    await Conversation.updateMany(
      { userId: userId },
      { isActive: false }
    );

    res.status(200).json({
      success: true,
      message: 'Chat history cleared successfully'
    });
  } catch (error) {
    console.error('Error clearing history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear chat history'
    });
  }
};

// Delete specific conversation
const deleteConversation = async (req, res) => {
  try {
    const { conversationId } = req.params;
    
    if (!conversationId) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID is required'
      });
    }

    const conversation = await Conversation.findOneAndDelete({ id: conversationId });
    
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Conversation deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting conversation:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete conversation'
    });
  }
};

module.exports = {
  getConversations,
  getActiveConversation,
  createConversation,
  addMessage,
  updateSettings,
  clearHistory,
  deleteConversation,
};










































