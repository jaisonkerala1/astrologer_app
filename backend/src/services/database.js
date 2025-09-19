const Database = require('better-sqlite3');
const path = require('path');

class DatabaseService {
  constructor() {
    // Create database file in the project root
    const dbPath = path.join(__dirname, '../../astrologer.db');
    this.db = new Database(dbPath);
    this.initializeTables();
  }

  initializeTables() {
    // Create astrologers table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS astrologers (
        id TEXT PRIMARY KEY,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        profilePicture TEXT,
        specializations TEXT, -- JSON string
        languages TEXT, -- JSON string
        experience INTEGER DEFAULT 0,
        ratePerMinute REAL DEFAULT 50,
        isOnline BOOLEAN DEFAULT FALSE,
        totalEarnings REAL DEFAULT 0,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create OTPs table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS otps (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        otp TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        expiresAt DATETIME NOT NULL,
        isUsed BOOLEAN DEFAULT FALSE,
        attempts INTEGER DEFAULT 0
      )
    `);

    // Create sessions table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        astrologerId TEXT NOT NULL,
        token TEXT UNIQUE NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (astrologerId) REFERENCES astrologers (id)
      )
    `);

    console.log('Database tables initialized successfully');
  }

  // OTP methods
  createOTP(phone, otp) {
    const otpId = Date.now().toString();
    const now = Date.now();
    const expiresAt = new Date(now + 5 * 60 * 1000); // 5 minutes

    const stmt = this.db.prepare(`
      INSERT INTO otps (id, phone, otp, createdAt, expiresAt, isUsed, attempts)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(otpId, phone, otp, now, expiresAt.toISOString(), false, 0);

    return {
      id: otpId,
      phone,
      otp,
      createdAt: now,
      expiresAt,
      isUsed: false,
      attempts: 0
    };
  }

  verifyOTP(phone, otp, otpId = null) {
    let stmt;
    let result;

    if (otpId) {
      stmt = this.db.prepare(`
        SELECT * FROM otps 
        WHERE id = ? AND phone = ? AND otp = ? AND isUsed = FALSE 
        AND expiresAt > datetime('now') AND attempts < 3
      `);
      result = stmt.get(otpId, phone, otp);
    } else {
      stmt = this.db.prepare(`
        SELECT * FROM otps 
        WHERE phone = ? AND otp = ? AND isUsed = FALSE 
        AND expiresAt > datetime('now') AND attempts < 3
        ORDER BY createdAt DESC LIMIT 1
      `);
      result = stmt.get(phone, otp);
    }

    if (result) {
      // Mark as used
      const updateStmt = this.db.prepare(`
        UPDATE otps SET isUsed = TRUE WHERE id = ?
      `);
      updateStmt.run(result.id);
      return result;
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
      specializations: JSON.stringify(['Vedic Astrology']),
      languages: JSON.stringify(['English']),
      experience: 0,
      ratePerMinute: 50,
      isOnline: false,
      totalEarnings: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const stmt = this.db.prepare(`
      INSERT INTO astrologers (
        id, phone, name, email, profilePicture, specializations, 
        languages, experience, ratePerMinute, isOnline, totalEarnings, 
        createdAt, updatedAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      astrologer.id, astrologer.phone, astrologer.name, astrologer.email,
      astrologer.profilePicture, astrologer.specializations, astrologer.languages,
      astrologer.experience, astrologer.ratePerMinute, astrologer.isOnline,
      astrologer.totalEarnings, astrologer.createdAt, astrologer.updatedAt
    );

    return this.findAstrologerById(astrologerId);
  }

  findAstrologerByPhone(phone) {
    const stmt = this.db.prepare('SELECT * FROM astrologers WHERE phone = ?');
    const result = stmt.get(phone);
    
    if (result) {
      return this.formatAstrologer(result);
    }
    return null;
  }

  findAstrologerById(id) {
    const stmt = this.db.prepare('SELECT * FROM astrologers WHERE id = ?');
    const result = stmt.get(id);
    
    if (result) {
      return this.formatAstrologer(result);
    }
    return null;
  }

  updateAstrologer(id, updates) {
    const setClause = Object.keys(updates).map(key => `${key} = ?`).join(', ');
    const values = Object.values(updates);
    values.push(new Date().toISOString()); // updatedAt
    values.push(id);

    const stmt = this.db.prepare(`
      UPDATE astrologers 
      SET ${setClause}, updatedAt = ? 
      WHERE id = ?
    `);

    stmt.run(...values);
    return this.findAstrologerById(id);
  }

  deleteAstrologer(id) {
    const stmt = this.db.prepare('DELETE FROM astrologers WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  // Session methods
  createSession(astrologerId, token) {
    const sessionId = Date.now().toString();
    const stmt = this.db.prepare(`
      INSERT INTO sessions (id, astrologerId, token, createdAt)
      VALUES (?, ?, ?, ?)
    `);

    stmt.run(sessionId, astrologerId, token, new Date().toISOString());

    return {
      id: sessionId,
      astrologerId,
      token,
      createdAt: new Date()
    };
  }

  findSessionByToken(token) {
    const stmt = this.db.prepare('SELECT * FROM sessions WHERE token = ?');
    return stmt.get(token);
  }

  deleteSession(token) {
    const stmt = this.db.prepare('DELETE FROM sessions WHERE token = ?');
    const result = stmt.run(token);
    return result.changes > 0;
  }

  // Cleanup expired data
  cleanup() {
    // Remove expired OTPs
    const otpStmt = this.db.prepare(`
      DELETE FROM otps WHERE expiresAt < datetime('now')
    `);
    otpStmt.run();

    // Remove old sessions (older than 30 days)
    const sessionStmt = this.db.prepare(`
      DELETE FROM sessions WHERE createdAt < datetime('now', '-30 days')
    `);
    sessionStmt.run();
  }

  // Helper method to format astrologer data
  formatAstrologer(dbResult) {
    return {
      id: dbResult.id,
      phone: dbResult.phone,
      name: dbResult.name,
      email: dbResult.email,
      profilePicture: dbResult.profilePicture,
      specializations: JSON.parse(dbResult.specializations),
      languages: JSON.parse(dbResult.languages),
      experience: dbResult.experience,
      ratePerMinute: dbResult.ratePerMinute,
      isOnline: Boolean(dbResult.isOnline),
      totalEarnings: dbResult.totalEarnings,
      createdAt: dbResult.createdAt,
      updatedAt: dbResult.updatedAt
    };
  }

  // Close database connection
  close() {
    this.db.close();
  }
}

// Create singleton instance
const databaseService = new DatabaseService();

// Cleanup every 5 minutes
setInterval(() => {
  databaseService.cleanup();
}, 5 * 60 * 1000);

module.exports = databaseService;
