const mongoose = require('mongoose');

const timeSlotSchema = new mongoose.Schema(
  {
    astrologerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Astrologer', required: true, index: true },
    date: { type: Date, required: true, index: true }, // normalized to 00:00:00 UTC for the day
    startTime: { type: String, required: true }, // "09:00"
    endTime: { type: String, required: true }, // "09:30"
    duration: { type: Number, default: 30 }, // minutes
    isAvailable: { type: Boolean, default: true },
    isBooked: { type: Boolean, default: false },
    consultationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Consultation', default: null },
    bufferTime: { type: Number, default: 15 }, // minutes
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

timeSlotSchema.index({ astrologerId: 1, date: 1, startTime: 1 }, { unique: true });

module.exports = mongoose.model('TimeSlot', timeSlotSchema);


