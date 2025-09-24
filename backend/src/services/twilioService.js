const twilio = require('twilio');

// Initialize Twilio client
let client = null;

// Only initialize if we have valid credentials
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  try {
    client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
  } catch (error) {
    console.warn('Twilio initialization failed:', error.message);
    client = null;
  }
}

// Send OTP via SMS
const sendOTP = async (phone, otp) => {
  try {
    // Check if Twilio client is properly initialized
    if (!client) {
      throw new Error('Twilio client not initialized. Please check your credentials.');
    }

    // For development/testing, log the OTP instead of sending SMS
    if (process.env.NODE_ENV === 'development' || process.env.TWILIO_DEBUG === 'true') {
      console.log(`🔐 OTP for ${phone}: ${otp}`);
      console.log(`📱 SMS would be sent to: ${phone}`);
      console.log(`📞 From: ${process.env.TWILIO_PHONE_NUMBER}`);
      return { success: true, messageId: 'debug-' + Date.now() };
    }

    // Send actual SMS via Twilio
    const message = await client.messages.create({
      body: `Your Astrologer App verification code is: ${otp}. This code will expire in 5 minutes.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone
    });

    console.log(`OTP sent successfully to ${phone}. Message SID: ${message.sid}`);
    return { success: true, messageId: message.sid };
  } catch (error) {
    console.error('Twilio SMS error:', error);
    
    // If A2P 10DLC error, provide helpful message
    if (error.message.includes('A2P') || error.message.includes('10DLC')) {
      console.log(`🔐 OTP for ${phone}: ${otp} (A2P 10DLC registration required)`);
      return { success: true, messageId: 'a2p-debug-' + Date.now() };
    }
    
    throw new Error(`Failed to send SMS: ${error.message}`);
  }
};

// Send notification SMS
const sendNotification = async (phone, message) => {
  try {
    if (process.env.NODE_ENV === 'development' || !client) {
      console.log(`Notification to ${phone}: ${message}`);
      return { success: true, messageId: 'dev-' + Date.now() };
    }

    const sms = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone
    });

    return { success: true, messageId: sms.sid };
  } catch (error) {
    console.error('Twilio notification error:', error);
    // For development, don't throw error, just log it
    if (process.env.NODE_ENV === 'development') {
      console.log(`Notification to ${phone}: ${message}`);
      return { success: true, messageId: 'dev-' + Date.now() };
    }
    throw new Error('Failed to send notification');
  }
};

// Verify phone number format
const validatePhoneNumber = (phone) => {
  // Remove all non-digit characters
  const cleaned = phone.replace(/\D/g, '');
  
  // Check if it's a valid length (10-15 digits)
  if (cleaned.length < 10 || cleaned.length > 15) {
    return false;
  }
  
  return true;
};

// Format phone number for Twilio
const formatPhoneNumber = (phone) => {
  const cleaned = phone.replace(/\D/g, '');
  
  // Add country code if not present
  if (cleaned.length === 10) {
    return '+1' + cleaned; // Default to US, change as needed
  }
  
  if (cleaned.length === 11 && cleaned.startsWith('1')) {
    return '+' + cleaned;
  }
  
  return '+' + cleaned;
};

module.exports = {
  sendOTP,
  sendNotification,
  validatePhoneNumber,
  formatPhoneNumber
};





