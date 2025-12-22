const express = require('express');
const router = express.Router();

const auth = require('../middleware/auth');
const Availability = require('../models/Availability');
const Holiday = require('../models/Holiday');
const TimeSlot = require('../models/TimeSlot');

// Apply authentication middleware to all calendar routes (Astrologer app)
router.use(auth);

// -------------------------
// Helpers
// -------------------------
const ok = (res, data, message) => res.json({ success: true, data, message });
const fail = (res, code, message, error) => res.status(code).json({ success: false, message, error });

const pad2 = (n) => String(n).padStart(2, '0');
const toYmd = (d) => `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;

const normalizeDateYmdToUtc = (ymd) => {
  // ymd: "YYYY-MM-DD"
  if (!ymd || typeof ymd !== 'string') return null;
  const [y, m, d] = ymd.split('-').map(Number);
  if (!y || !m || !d) return null;
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
};

const parseTimeToMinutes = (t) => {
  const [h, m] = String(t || '').split(':').map(Number);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  return h * 60 + m;
};

const minutesToTime = (mins) => `${pad2(Math.floor(mins / 60))}:${pad2(mins % 60)}`;

const sameAstrologerGuard = (req, res, astrologerId) => {
  const tokenAstrologerId = String(req.user?.astrologerId || '');
  if (!astrologerId || String(astrologerId) !== tokenAstrologerId) {
    fail(res, 403, 'Forbidden', 'Astrologer ID does not match token');
    return false;
  }
  return true;
};

const isHolidayOnDate = (holiday, targetYmd) => {
  const holidayYmd = toYmd(new Date(holiday.date));
  if (!holiday.isRecurring) return holidayYmd === targetYmd;

  const target = normalizeDateYmdToUtc(targetYmd);
  const hd = new Date(holiday.date);
  const pattern = holiday.recurringPattern;

  if (!target) return holidayYmd === targetYmd;
  if (pattern === 'yearly') return hd.getUTCMonth() === target.getUTCMonth() && hd.getUTCDate() === target.getUTCDate();
  if (pattern === 'monthly') return hd.getUTCDate() === target.getUTCDate();
  if (pattern === 'weekly') return hd.getUTCDay() === target.getUTCDay();

  return holidayYmd === targetYmd;
};

// -------------------------
// Availability
// -------------------------

/**
 * GET /api/calendar/availability/:astrologerId
 */
router.get('/availability/:astrologerId', async (req, res) => {
  try {
    if (!sameAstrologerGuard(req, res, req.params.astrologerId)) return;

    const items = await Availability.find({ astrologerId: req.params.astrologerId }).sort({ dayOfWeek: 1, startTime: 1 });
    return ok(res, items);
  } catch (e) {
    return fail(res, 500, 'Failed to load availability', e.message);
  }
});

/**
 * POST /api/calendar/availability
 * body: { astrologerId, dayOfWeek, startTime, endTime, isActive, breaks: [{startTime,endTime,reason}] }
 */
router.post('/availability', async (req, res) => {
  try {
    const { astrologerId, dayOfWeek, startTime, endTime, isActive, breaks } = req.body || {};
    if (!sameAstrologerGuard(req, res, astrologerId)) return;

    if (dayOfWeek === undefined || dayOfWeek === null) return fail(res, 400, 'dayOfWeek is required');
    if (!startTime || !endTime) return fail(res, 400, 'startTime and endTime are required');

    const item = await Availability.create({
      astrologerId,
      dayOfWeek,
      startTime,
      endTime,
      isActive: isActive !== undefined ? !!isActive : true,
      breaks: Array.isArray(breaks) ? breaks : [],
    });

    return ok(res, item, 'Availability created');
  } catch (e) {
    return fail(res, 500, 'Failed to create availability', e.message);
  }
});

/**
 * PUT /api/calendar/availability/:id
 */
router.put('/availability/:id', async (req, res) => {
  try {
    const existing = await Availability.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Availability not found');
    if (!sameAstrologerGuard(req, res, existing.astrologerId)) return;

    const { dayOfWeek, startTime, endTime, isActive, breaks } = req.body || {};
    if (dayOfWeek !== undefined) existing.dayOfWeek = dayOfWeek;
    if (startTime) existing.startTime = startTime;
    if (endTime) existing.endTime = endTime;
    if (isActive !== undefined) existing.isActive = !!isActive;
    if (Array.isArray(breaks)) existing.breaks = breaks;

    await existing.save();
    return ok(res, existing, 'Availability updated');
  } catch (e) {
    return fail(res, 500, 'Failed to update availability', e.message);
  }
});

/**
 * DELETE /api/calendar/availability/:id
 */
router.delete('/availability/:id', async (req, res) => {
  try {
    const existing = await Availability.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Availability not found');
    if (!sameAstrologerGuard(req, res, existing.astrologerId)) return;

    await Availability.deleteOne({ _id: existing._id });
    return ok(res, { id: req.params.id }, 'Availability deleted');
  } catch (e) {
    return fail(res, 500, 'Failed to delete availability', e.message);
  }
});

// -------------------------
// Holidays
// -------------------------

/**
 * GET /api/calendar/holidays/:astrologerId
 */
router.get('/holidays/:astrologerId', async (req, res) => {
  try {
    if (!sameAstrologerGuard(req, res, req.params.astrologerId)) return;

    const items = await Holiday.find({ astrologerId: req.params.astrologerId }).sort({ date: 1 });
    return ok(res, items);
  } catch (e) {
    return fail(res, 500, 'Failed to load holidays', e.message);
  }
});

/**
 * POST /api/calendar/holidays
 * body: { astrologerId, date, reason, isRecurring, recurringPattern }
 */
router.post('/holidays', async (req, res) => {
  try {
    const { astrologerId, date, reason, isRecurring, recurringPattern } = req.body || {};
    if (!sameAstrologerGuard(req, res, astrologerId)) return;
    if (!date) return fail(res, 400, 'date is required');

    const dt = new Date(date);
    if (Number.isNaN(dt.getTime())) return fail(res, 400, 'Invalid date');

    const item = await Holiday.create({
      astrologerId,
      date: dt,
      reason: reason || '',
      isRecurring: !!isRecurring,
      recurringPattern: isRecurring ? recurringPattern || 'yearly' : null,
    });

    return ok(res, item, 'Holiday created');
  } catch (e) {
    return fail(res, 500, 'Failed to create holiday', e.message);
  }
});

/**
 * DELETE /api/calendar/holidays/:id
 */
router.delete('/holidays/:id', async (req, res) => {
  try {
    const existing = await Holiday.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Holiday not found');
    if (!sameAstrologerGuard(req, res, existing.astrologerId)) return;

    await Holiday.deleteOne({ _id: existing._id });
    return ok(res, { id: req.params.id }, 'Holiday deleted');
  } catch (e) {
    return fail(res, 500, 'Failed to delete holiday', e.message);
  }
});

// -------------------------
// Time slots (derived from weekly availability + holidays)
// -------------------------

/**
 * GET /api/calendar/time-slots/:astrologerId/:date
 * date: "YYYY-MM-DD"
 */
router.get('/time-slots/:astrologerId/:date', async (req, res) => {
  try {
    const { astrologerId, date } = req.params;
    if (!sameAstrologerGuard(req, res, astrologerId)) return;

    const day = normalizeDateYmdToUtc(date);
    if (!day) return fail(res, 400, 'Invalid date. Use YYYY-MM-DD');

    const slots = await TimeSlot.find({ astrologerId, date: day }).sort({ startTime: 1 });
    return ok(res, slots);
  } catch (e) {
    return fail(res, 500, 'Failed to load time slots', e.message);
  }
});

/**
 * POST /api/calendar/generate-time-slots
 * body: { astrologerId, date: "YYYY-MM-DD", duration?: number, bufferTime?: number }
 */
router.post('/generate-time-slots', async (req, res) => {
  try {
    const { astrologerId, date, duration = 30, bufferTime = 15 } = req.body || {};
    if (!sameAstrologerGuard(req, res, astrologerId)) return;

    const day = normalizeDateYmdToUtc(date);
    if (!day) return fail(res, 400, 'Invalid date. Use YYYY-MM-DD');

    const targetYmd = toYmd(day);

    const holidays = await Holiday.find({ astrologerId });
    const isHoliday = holidays.some((h) => isHolidayOnDate(h, targetYmd));
    if (isHoliday) {
      // If holiday, mark existing non-booked slots unavailable (keep booked slots)
      await TimeSlot.updateMany({ astrologerId, date: day, isBooked: false }, { $set: { isAvailable: false } });
      const slots = await TimeSlot.find({ astrologerId, date: day }).sort({ startTime: 1 });
      return ok(res, slots, 'Holiday - no available slots');
    }

    const dayOfWeek = day.getUTCDay(); // 0..6
    const availabilityRules = await Availability.find({ astrologerId, dayOfWeek, isActive: true }).sort({ startTime: 1 });

    if (availabilityRules.length === 0) {
      // No availability -> mark existing non-booked slots unavailable
      await TimeSlot.updateMany({ astrologerId, date: day, isBooked: false }, { $set: { isAvailable: false } });
      const slots = await TimeSlot.find({ astrologerId, date: day }).sort({ startTime: 1 });
      return ok(res, slots, 'No availability for this day');
    }

    const existingSlots = await TimeSlot.find({ astrologerId, date: day });
    const byStart = new Map(existingSlots.map((s) => [s.startTime, s]));

    const keepStartTimes = new Set();
    const toInsert = [];

    // Build intervals from availability rules excluding breaks
    for (const rule of availabilityRules) {
      const startMin = parseTimeToMinutes(rule.startTime);
      const endMin = parseTimeToMinutes(rule.endTime);
      if (startMin === null || endMin === null || endMin <= startMin) continue;

      const breakRanges = (rule.breaks || [])
        .map((b) => ({
          start: parseTimeToMinutes(b.startTime),
          end: parseTimeToMinutes(b.endTime),
        }))
        .filter((b) => b.start !== null && b.end !== null && b.end > b.start)
        .sort((a, b) => a.start - b.start);

      // Create a list of "available ranges" by subtracting breaks (simple: handle each break sequentially)
      let cursor = startMin;
      const ranges = [];
      for (const br of breakRanges) {
        if (br.start > cursor) ranges.push({ start: cursor, end: br.start });
        cursor = Math.max(cursor, br.end);
      }
      if (cursor < endMin) ranges.push({ start: cursor, end: endMin });

      for (const r of ranges) {
        let t = r.start;
        while (t + duration <= r.end) {
          const startTime = minutesToTime(t);
          const endTime = minutesToTime(t + duration);
          keepStartTimes.add(startTime);

          const existing = byStart.get(startTime);
          if (!existing) {
            toInsert.push({
              astrologerId,
              date: day,
              startTime,
              endTime,
              duration,
              bufferTime,
              isAvailable: true,
              isBooked: false,
              consultationId: null,
            });
          } else if (!existing.isBooked) {
            // Keep slot but make sure it's available and times match current duration
            existing.endTime = endTime;
            existing.duration = duration;
            existing.bufferTime = bufferTime;
            existing.isAvailable = true;
            await existing.save();
          }

          t += duration;
        }
      }
    }

    if (toInsert.length > 0) {
      await TimeSlot.insertMany(toInsert, { ordered: false }).catch(() => {});
    }

    // Mark any existing non-booked slots that are not in the new schedule as unavailable
    const stale = existingSlots.filter((s) => !s.isBooked && !keepStartTimes.has(s.startTime));
    if (stale.length > 0) {
      await TimeSlot.updateMany(
        { _id: { $in: stale.map((s) => s._id) } },
        { $set: { isAvailable: false } }
      );
    }

    const slots = await TimeSlot.find({ astrologerId, date: day }).sort({ startTime: 1 });
    return ok(res, slots, 'Time slots generated');
  } catch (e) {
    return fail(res, 500, 'Failed to generate time slots', e.message);
  }
});

/**
 * POST /api/calendar/book-slot
 * body: { slotId, consultationId }
 */
router.post('/book-slot', async (req, res) => {
  try {
    const { slotId, consultationId } = req.body || {};
    if (!slotId) return fail(res, 400, 'slotId is required');

    const slot = await TimeSlot.findById(slotId);
    if (!slot) return fail(res, 404, 'Time slot not found');
    if (!sameAstrologerGuard(req, res, slot.astrologerId)) return;

    if (slot.isBooked) return fail(res, 409, 'Time slot already booked');
    slot.isBooked = true;
    slot.isAvailable = false;
    slot.consultationId = consultationId || null;
    await slot.save();

    return ok(res, slot, 'Time slot booked');
  } catch (e) {
    return fail(res, 500, 'Failed to book time slot', e.message);
  }
});

/**
 * POST /api/calendar/cancel-booking
 * body: { slotId }
 */
router.post('/cancel-booking', async (req, res) => {
  try {
    const { slotId } = req.body || {};
    if (!slotId) return fail(res, 400, 'slotId is required');

    const slot = await TimeSlot.findById(slotId);
    if (!slot) return fail(res, 404, 'Time slot not found');
    if (!sameAstrologerGuard(req, res, slot.astrologerId)) return;

    slot.isBooked = false;
    slot.isAvailable = true;
    slot.consultationId = null;
    await slot.save();

    return ok(res, slot, 'Booking cancelled');
  } catch (e) {
    return fail(res, 500, 'Failed to cancel booking', e.message);
  }
});

module.exports = router;


