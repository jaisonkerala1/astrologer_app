const axios = require('axios');

class OpenRouterService {
  constructor() {
    this.apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    this.apiKey = process.env.OPENROUTER_API_KEY;
    this.model = 'anthropic/claude-3-haiku';
  }

  async generateResponse({ userMessage, conversationHistory, userProfile, settings }) {
    try {
      if (!this.apiKey) {
        throw new Error('OpenRouter API key is not configured');
      }

      // Build context for Loona
      const context = this._buildContext(userProfile, settings);
      
      // Prepare messages for the API
      const messages = this._prepareMessages(context, conversationHistory, userMessage);
      
      const response = await axios.post(
        this.apiUrl,
        {
          model: this.model,
          messages: messages,
          max_tokens: 800,
          temperature: 0.3,
          top_p: 0.8,
          frequency_penalty: 0.0,
          presence_penalty: 0.0,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://astrologer-app.com',
            'X-Title': 'Astrologer App',
          }
        }
      );

      if (response.status === 200 && response.data?.choices?.[0]?.message?.content) {
        return response.data.choices[0].message.content.trim();
      } else {
        throw new Error('Invalid response from OpenRouter API');
      }
    } catch (error) {
      console.error('OpenRouter Service Error:', error.message);
      if (error.response) {
        console.error('Response Status:', error.response.status);
        console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
      }
      throw error;
    }
  }

  _buildContext(userProfile, settings) {
    const contextParts = [];
    
    // Loona's professional identity and role
    contextParts.push("You are Loona, a professional AI assistant specialized in astrology and designed to support professional astrologers. You provide accurate, insightful, and helpful guidance while maintaining the highest standards of professionalism.");
    contextParts.push("");
    
    // Core expertise areas
    contextParts.push("Your Expertise:");
    contextParts.push("- Advanced astrological knowledge including natal charts, transits, progressions, and synastry");
    contextParts.push("- Professional astrology practice guidance and business advice");
    contextParts.push("- App features and functionality support");
    contextParts.push("- Client consultation best practices");
    contextParts.push("- Astrological software and tools guidance");
    contextParts.push("");
    
    // User context if available and sharing is enabled
    if (userProfile && (settings?.shareUserInfo ?? true)) {
      contextParts.push("Astrologer Profile:");
      contextParts.push(`- Name: ${userProfile.name}`);
      contextParts.push(`- Professional Experience: ${userProfile.experience} years`);
      contextParts.push(`- Specializations: ${userProfile.specializations?.join(', ')}`);
      contextParts.push(`- Languages: ${userProfile.languages?.join(', ')}`);
      contextParts.push("");
    }
    
    // Professional guidelines for responses
    contextParts.push("Professional Guidelines:");
    contextParts.push("- Maintain a professional yet approachable tone");
    contextParts.push("- Provide accurate, evidence-based astrological information");
    contextParts.push("- Offer practical solutions and actionable advice");
    contextParts.push("- Respect the astrologer's expertise and experience level");
    contextParts.push("- Keep responses focused, informative, and relevant");
    contextParts.push("- Acknowledge limitations and suggest professional resources when appropriate");
    contextParts.push("");
    
    // Response formatting guidelines
    contextParts.push("Response Format:");
    contextParts.push("- Keep responses concise yet comprehensive (aim for 2-4 paragraphs)");
    contextParts.push("- Use bullet points for lists and key information");
    contextParts.push("- Highlight important terms or concepts with emphasis");
    contextParts.push("- Include practical examples when relevant");
    contextParts.push("- End with a follow-up question or suggestion when appropriate");
    
    return contextParts.join("\n");
  }

  _prepareMessages(context, conversationHistory, userMessage) {
    const messages = [
      {
        role: 'system',
        content: context
      }
    ];
    
    // Add recent conversation history (last 10 messages for context)
    const recentHistory = conversationHistory.slice(-10);
    for (const msg of recentHistory) {
      if (!msg.isTyping) {
        messages.push({
          role: msg.isFromUser ? 'user' : 'assistant',
          content: msg.content
        });
      }
    }
    
    // Add current user message
    messages.push({
      role: 'user',
      content: userMessage
    });
    
    return messages;
  }

  _getFallbackResponse(userProfile) {
    const name = userProfile?.name || 'there';
    return `Hello ${name}! I'm experiencing a temporary connection issue. Please try again in a moment, or feel free to explore the app's features in the meantime. I'm here to help with your astrology practice whenever you need assistance! 🌟`;
  }
}

module.exports = new OpenRouterService();

