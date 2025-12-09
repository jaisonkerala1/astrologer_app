const openRouterService = require('../services/openRouterService');

// Generate AI response from Loona
const generateResponse = async (req, res) => {
  try {
    const { userMessage, conversationHistory, userProfile, settings } = req.body;
    
    if (!userMessage) {
      return res.status(400).json({
        success: false,
        message: 'User message is required'
      });
    }

    // Call OpenRouter service to generate response
    const response = await openRouterService.generateResponse({
      userMessage,
      conversationHistory: conversationHistory || [],
      userProfile: userProfile || null,
      settings: settings || {}
    });

    res.status(200).json({
      success: true,
      data: {
        response: response
      }
    });
  } catch (error) {
    console.error('Loona AI Error:', error);
    
    // Return a user-friendly error with fallback response
    const fallbackResponse = "I'm having trouble connecting right now. Please try again in a moment. I'm here to help with your astrology practice! 🌟";
    
    res.status(200).json({
      success: true,
      data: {
        response: fallbackResponse,
        error: error.message
      }
    });
  }
};

module.exports = {
  generateResponse
};

