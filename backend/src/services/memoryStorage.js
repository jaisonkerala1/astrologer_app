// Simple in-memory storage for development/testing
class MemoryStorage {
  constructor() {
    this.otps = new Map();
    this.astrologers = new Map();
    this.sessions = new Map();
    
    // Pre-populate with test user for demo
    this.createTestUser();
  }

  createTestUser() {
    const testUser = {
      id: 'test_user_1',
      phone: '+918050381803',
      name: 'Demo Astrologer',
      email: 'demo@astrologer.com',
      profilePicture: null,
      specializations: ['Vedic Astrology', 'Tarot Reading'],
      languages: ['English', 'Hindi'],
      experience: 5,
      ratePerMinute: 75,
      isOnline: false,
      totalEarnings: 12500.0,
      createdAt: new Date('2024-01-01'),
      updatedAt: new Date()
    };
    this.astrologers.set(testUser.id, testUser);
    console.log('MemoryStorage: Created test user for phone:', testUser.phone);
  }

  // OTP methods
  createOTP(phone, otp) {
    const otpId = Date.now().toString();
    const now = Date.now();
    const otpData = {
      id: otpId,
      phone,
      otp,
      createdAt: now,
      expiresAt: new Date(now + 5 * 60 * 1000), // 5 minutes
      isUsed: false,
      attempts: 0
    };
    this.otps.set(otpId, otpData);
    return otpData;
  }

  verifyOTP(phone, otp, otpId = null) {
    // If otpId is provided, verify using specific OTP record
    if (otpId) {
      const otpData = this.otps.get(otpId);
      if (otpData && 
          otpData.phone === phone && 
          otpData.otp === otp && 
          !otpData.isUsed && 
          otpData.expiresAt > new Date() && 
          otpData.attempts < 3) {
        otpData.isUsed = true;
        return otpData;
      }
      return null;
    }
    
    // Fallback to searching all OTPs
    for (const [id, otpData] of this.otps.entries()) {
      if (otpData.phone === phone && 
          otpData.otp === otp && 
          !otpData.isUsed && 
          otpData.expiresAt > new Date() && 
          otpData.attempts < 3) {
        otpData.isUsed = true;
        return otpData;
      }
    }
    return null;
  }

  // Astrologer methods
  createAstrologer(phone) {
    const astrologerId = Date.now().toString();
    const astrologer = {
      id: astrologerId,
      phone,
      name: 'Astrologer',
      email: `${phone}@astrologer.com`,
      profilePicture: null,
      specializations: ['Vedic Astrology'],
      languages: ['English'],
      experience: 0,
      ratePerMinute: 50,
      isOnline: false,
      totalEarnings: 0,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    this.astrologers.set(astrologerId, astrologer);
    return astrologer;
  }

  findAstrologerByPhone(phone) {
    for (const [id, astrologer] of this.astrologers.entries()) {
      if (astrologer.phone === phone) {
        return astrologer;
      }
    }
    return null;
  }

  findAstrologerById(id) {
    return this.astrologers.get(id);
  }

  updateAstrologer(id, updates) {
    const astrologer = this.astrologers.get(id);
    if (astrologer) {
      Object.assign(astrologer, updates, { updatedAt: new Date() });
      return astrologer;
    }
    return null;
  }

  // Session methods
  createSession(astrologerId, token) {
    const sessionId = Date.now().toString();
    const session = {
      id: sessionId,
      astrologerId,
      token,
      createdAt: new Date()
    };
    this.sessions.set(sessionId, session);
    return session;
  }

  findSessionByToken(token) {
    for (const [id, session] of this.sessions.entries()) {
      if (session.token === token) {
        return session;
      }
    }
    return null;
  }

  // Cleanup expired data
  cleanup() {
    const now = new Date();
    
    // Remove expired OTPs
    for (const [id, otpData] of this.otps.entries()) {
      if (otpData.expiresAt < now) {
        this.otps.delete(id);
      }
    }
  }
}

// Create singleton instance
const memoryStorage = new MemoryStorage();

// Cleanup every 5 minutes
setInterval(() => {
  memoryStorage.cleanup();
}, 5 * 60 * 1000);

module.exports = memoryStorage;


