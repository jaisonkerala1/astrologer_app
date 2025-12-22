const mongoose = require('mongoose');

const breakTimeSchema = new mongoose.Schema(
  {
    startTime: { type: String, required: true }, // "13:00"
    endTime: { type: String, required: true }, // "14:00"
    reason: { type: String, default: '' },
  },
  { _id: false }
);

const availabilitySchema = new mongoose.Schema(
  {
    astrologerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Astrologer', required: true, index: true },
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 }, // 0=Sun..6=Sat
    startTime: { type: String, required: true, default: '09:00' },
    endTime: { type: String, required: true, default: '18:00' },
    isActive: { type: Boolean, default: true },
    breaks: { type: [breakTimeSchema], default: [] },
  },
  { timestamps: true }
);

availabilitySchema.index({ astrologerId: 1, dayOfWeek: 1 });

module.exports = mongoose.model('Availability', availabilitySchema);


