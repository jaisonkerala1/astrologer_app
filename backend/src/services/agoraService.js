/**
 * Agora Token Generation Service
 * Generates RTC tokens for live streaming
 */

const crypto = require('crypto');

class AgoraTokenGenerator {
  constructor(appId, appCertificate) {
    this.appId = appId;
    this.appCertificate = appCertificate;
  }

  // Role constants
  static get Role() {
    return {
      PUBLISHER: 1,    // Broadcaster
      SUBSCRIBER: 2    // Audience
    };
  }

  /**
   * Generate RTC token for live streaming
   * @param {string} channelName - Channel name
   * @param {number} uid - User ID (0 for auto-assign)
   * @param {number} role - 1 for publisher, 2 for subscriber
   * @param {number} expireTime - Token expiration in seconds (default 24 hours)
   */
  generateRtcToken(channelName, uid, role, expireTime = 86400) {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expireTime;

    // Build token
    const token = this._buildToken(channelName, uid, role, privilegeExpiredTs);
    return token;
  }

  _buildToken(channelName, uid, role, privilegeExpiredTs) {
    // Token version
    const VERSION = '007';
    
    // Create message
    const message = this._packMessage(uid, role, privilegeExpiredTs);
    
    // Create signature
    const signature = this._generateSignature(channelName, uid, message);
    
    // Create content
    const content = this._packContent(signature, message);
    
    // Encode to base64
    const token = VERSION + Buffer.from(this.appId + content).toString('base64');
    
    return token;
  }

  _packMessage(uid, role, privilegeExpiredTs) {
    const privileges = {};
    
    // Join channel privilege
    privileges[1] = privilegeExpiredTs;
    
    // Publish audio privilege
    privileges[2] = privilegeExpiredTs;
    
    // Publish video privilege  
    privileges[3] = privilegeExpiredTs;
    
    // Publish data stream privilege
    privileges[4] = privilegeExpiredTs;
    
    // RTM login privilege
    privileges[5] = privilegeExpiredTs;

    // Pack salt and ts
    const salt = Math.floor(Math.random() * 0xFFFFFFFF);
    const ts = Math.floor(Date.now() / 1000);

    // Pack message buffer
    let buffer = Buffer.alloc(0);
    buffer = this._appendUint32(buffer, salt);
    buffer = this._appendUint32(buffer, ts);
    buffer = this._appendUint32(buffer, Object.keys(privileges).length);

    for (const [key, value] of Object.entries(privileges)) {
      buffer = this._appendUint16(buffer, parseInt(key));
      buffer = this._appendUint32(buffer, value);
    }

    return buffer;
  }

  _generateSignature(channelName, uid, message) {
    // Create sign content
    const content = Buffer.concat([
      Buffer.from(this.appId),
      Buffer.from(channelName),
      this._packUid(uid),
      message
    ]);

    // HMAC-SHA256
    const hmac = crypto.createHmac('sha256', this.appCertificate);
    hmac.update(content);
    return hmac.digest();
  }

  _packContent(signature, message) {
    let buffer = Buffer.alloc(0);
    buffer = this._appendBytes(buffer, signature);
    buffer = this._appendBytes(buffer, message);
    return buffer.toString('base64');
  }

  _packUid(uid) {
    if (uid === 0) {
      return Buffer.alloc(0);
    }
    return Buffer.from(uid.toString());
  }

  _appendUint16(buffer, value) {
    const b = Buffer.alloc(2);
    b.writeUInt16LE(value, 0);
    return Buffer.concat([buffer, b]);
  }

  _appendUint32(buffer, value) {
    const b = Buffer.alloc(4);
    b.writeUInt32LE(value, 0);
    return Buffer.concat([buffer, b]);
  }

  _appendBytes(buffer, bytes) {
    return Buffer.concat([
      this._appendUint16(buffer, bytes.length),
      bytes
    ]);
  }
}

// Alternative: Use Agora's official token builder approach
// This is a simplified implementation - for production, use official SDK

/**
 * Simple token generator using official algorithm
 */
function generateAgoraToken(appId, appCertificate, channelName, uid, role, expireTimeInSeconds = 86400) {
  if (!appId || !appCertificate) {
    throw new Error('Agora App ID and Certificate are required');
  }

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expireTimeInSeconds;

  // Use the token generator
  const generator = new AgoraTokenGenerator(appId, appCertificate);
  return generator.generateRtcToken(channelName, uid, role, expireTimeInSeconds);
}

module.exports = {
  AgoraTokenGenerator,
  generateAgoraToken,
  Role: AgoraTokenGenerator.Role
};

