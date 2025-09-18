const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: true,
    trim: true
  },
  otp: {
    type: String,
    required: true,
    length: 6
  },
  expiresAt: {
    type: Date,
    required: true,
    default: () => new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
  },
  isUsed: {
    type: Boolean,
    default: false
  },
  attempts: {
    type: Number,
    default: 0,
    max: 3
  }
}, {
  timestamps: true
});

// Index for better query performance
otpSchema.index({ phone: 1 });
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // Auto-delete expired OTPs

// Method to check if OTP is valid
otpSchema.methods.isValid = function() {
  return !this.isUsed && this.expiresAt > new Date() && this.attempts < 3;
};

// Method to mark as used
otpSchema.methods.markAsUsed = function() {
  this.isUsed = true;
  return this.save();
};

// Method to increment attempts
otpSchema.methods.incrementAttempts = function() {
  this.attempts += 1;
  return this.save();
};

// Static method to generate OTP
otpSchema.statics.generateOTP = function() {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Static method to create OTP for phone
otpSchema.statics.createForPhone = async function(phone) {
  // Invalidate any existing OTPs for this phone
  await this.updateMany(
    { phone, isUsed: false },
    { isUsed: true }
  );
  
  const otp = this.generateOTP();
  return this.create({
    phone,
    otp,
    expiresAt: new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
  });
};

// Static method to verify OTP
otpSchema.statics.verifyOTP = async function(phone, otp) {
  const otpRecord = await this.findOne({
    phone,
    otp,
    isUsed: false,
    expiresAt: { $gt: new Date() }
  });
  
  if (!otpRecord) {
    // Increment attempts for any existing OTP for this phone
    await this.updateOne(
      { phone, isUsed: false },
      { $inc: { attempts: 1 } }
    );
    return null;
  }
  
  // Mark as used
  await otpRecord.markAsUsed();
  return otpRecord;
};

module.exports = mongoose.model('OTP', otpSchema);









