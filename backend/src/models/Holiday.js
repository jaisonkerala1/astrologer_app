const mongoose = require('mongoose');

const holidaySchema = new mongoose.Schema(
  {
    astrologerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Astrologer', required: true, index: true },
    date: { type: Date, required: true, index: true }, // stored as Date (UTC)
    reason: { type: String, default: '' },
    isRecurring: { type: Boolean, default: false },
    recurringPattern: { type: String, enum: ['yearly', 'monthly', 'weekly'], default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

holidaySchema.index({ astrologerId: 1, date: 1 });

module.exports = mongoose.model('Holiday', holidaySchema);


