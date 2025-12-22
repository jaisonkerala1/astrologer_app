const express = require('express');
const router = express.Router();

const adminAuth = require('../middleware/adminAuth');
const Astrologer = require('../models/Astrologer');
const Availability = require('../models/Availability');
const Holiday = require('../models/Holiday');

router.use(adminAuth);

// -------------------------
// Helpers
// -------------------------
const ok = (res, data, message) => res.json({ success: true, data, message });
const fail = (res, code, message, error) => res.status(code).json({ success: false, message, error });

const pad2 = (n) => String(n).padStart(2, '0');
const toYmd = (d) => `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
const normalizeDateYmdToUtc = (ymd) => {
  if (!ymd || typeof ymd !== 'string') return null;
  const [y, m, d] = ymd.split('-').map(Number);
  if (!y || !m || !d) return null;
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
};

const timeToMinutes = (t) => {
  const [h, m] = String(t || '').split(':').map(Number);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  return h * 60 + m;
};

const toSlotsLabel = (rule) => {
  if (!rule?.isActive) return [];
  const out = [];
  const start = timeToMinutes(rule.startTime);
  const end = timeToMinutes(rule.endTime);
  if (start === null || end === null || end <= start) return [];

  // Simple break subtraction (supports multiple breaks)
  const breaks = (rule.breaks || [])
    .map((b) => ({ start: timeToMinutes(b.startTime), end: timeToMinutes(b.endTime) }))
    .filter((b) => b.start !== null && b.end !== null && b.end > b.start)
    .sort((a, b) => a.start - b.start);

  let cursor = start;
  for (const br of breaks) {
    if (br.start > cursor) out.push({ start: cursor, end: br.start });
    cursor = Math.max(cursor, br.end);
  }
  if (cursor < end) out.push({ start: cursor, end });

  return out
    .filter((r) => r.end - r.start >= 30)
    .map((r) => `${pad2(Math.floor(r.start / 60))}:${pad2(r.start % 60)}-${pad2(Math.floor(r.end / 60))}:${pad2(r.end % 60)}`);
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
// Admin summaries (for dashboard)
// -------------------------

/**
 * GET /api/admin/calendar/availability/all?date=YYYY-MM-DD
 * Returns an array of summary objects:
 * { astrologerId, astrologerName, profilePicture, isOnline, todayAvailable, todaySlots, upcomingHolidays, weeklyAvailability }
 */
router.get('/availability/all', async (req, res) => {
  try {
    const date = req.query.date ? String(req.query.date) : toYmd(new Date());
    const day = normalizeDateYmdToUtc(date);
    if (!day) return fail(res, 400, 'Invalid date. Use YYYY-MM-DD');

    const targetYmd = toYmd(day);
    const dayOfWeek = day.getUTCDay();

    const astrologers = await Astrologer.find({}, { name: 1, profilePicture: 1, isOnline: 1 }).sort({ name: 1 });
    const astrologerIds = astrologers.map((a) => a._id);

    const [allAvailability, allHolidays] = await Promise.all([
      Availability.find({ astrologerId: { $in: astrologerIds } }),
      Holiday.find({ astrologerId: { $in: astrologerIds } }),
    ]);

    const availabilityByAstro = new Map();
    for (const a of allAvailability) {
      const key = String(a.astrologerId);
      if (!availabilityByAstro.has(key)) availabilityByAstro.set(key, []);
      availabilityByAstro.get(key).push(a);
    }

    const holidaysByAstro = new Map();
    for (const h of allHolidays) {
      const key = String(h.astrologerId);
      if (!holidaysByAstro.has(key)) holidaysByAstro.set(key, []);
      holidaysByAstro.get(key).push(h);
    }

    const now = new Date();
    const upcomingEnd = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const summaries = astrologers.map((a) => {
      const id = String(a._id);
      const weeklyAvailability = (availabilityByAstro.get(id) || []).slice().sort((x, y) => x.dayOfWeek - y.dayOfWeek);
      const holidays = holidaysByAstro.get(id) || [];

      const upcomingHolidays = holidays
        .filter((h) => {
          const hd = new Date(h.date);
          return hd >= now && hd <= upcomingEnd;
        })
        .sort((x, y) => new Date(x.date) - new Date(y.date));

      const isHoliday = holidays.some((h) => isHolidayOnDate(h, targetYmd));
      const todaysRules = weeklyAvailability.filter((r) => r.dayOfWeek === dayOfWeek && r.isActive);
      const todaySlots = isHoliday ? [] : todaysRules.flatMap((r) => toSlotsLabel(r));

      return {
        astrologerId: id,
        astrologerName: a.name,
        profilePicture: a.profilePicture || null,
        isOnline: !!a.isOnline,
        todayAvailable: !!a.isOnline && todaySlots.length > 0,
        todaySlots,
        upcomingHolidays,
        weeklyAvailability,
      };
    });

    return ok(res, summaries);
  } catch (e) {
    return fail(res, 500, 'Failed to load availability summaries', e.message);
  }
});

/**
 * GET /api/admin/calendar/availability/:astrologerId
 */
router.get('/availability/:astrologerId', async (req, res) => {
  try {
    const { astrologerId } = req.params;
    const [availability, holidays] = await Promise.all([
      Availability.find({ astrologerId }).sort({ dayOfWeek: 1, startTime: 1 }),
      Holiday.find({ astrologerId }).sort({ date: 1 }),
    ]);
    return ok(res, { availability, holidays });
  } catch (e) {
    return fail(res, 500, 'Failed to load astrologer availability', e.message);
  }
});

// -------------------------
// Admin CRUD: Availability
// -------------------------

router.post('/availability', async (req, res) => {
  try {
    const { astrologerId, dayOfWeek, startTime, endTime, isActive, breaks } = req.body || {};
    if (!astrologerId) return fail(res, 400, 'astrologerId is required');
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

router.put('/availability/:id', async (req, res) => {
  try {
    const existing = await Availability.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Availability not found');

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

router.delete('/availability/:id', async (req, res) => {
  try {
    const existing = await Availability.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Availability not found');
    await Availability.deleteOne({ _id: existing._id });
    return ok(res, { id: req.params.id }, 'Availability deleted');
  } catch (e) {
    return fail(res, 500, 'Failed to delete availability', e.message);
  }
});

// -------------------------
// Admin CRUD: Holidays
// -------------------------

router.get('/holidays/all', async (req, res) => {
  try {
    const items = await Holiday.find({}).sort({ date: 1 });
    return ok(res, items);
  } catch (e) {
    return fail(res, 500, 'Failed to load holidays', e.message);
  }
});

router.get('/holidays/:astrologerId', async (req, res) => {
  try {
    const items = await Holiday.find({ astrologerId: req.params.astrologerId }).sort({ date: 1 });
    return ok(res, items);
  } catch (e) {
    return fail(res, 500, 'Failed to load holidays', e.message);
  }
});

router.post('/holidays', async (req, res) => {
  try {
    const { astrologerId, date, reason, isRecurring, recurringPattern } = req.body || {};
    if (!astrologerId) return fail(res, 400, 'astrologerId is required');
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

router.delete('/holidays/:id', async (req, res) => {
  try {
    const existing = await Holiday.findById(req.params.id);
    if (!existing) return fail(res, 404, 'Holiday not found');
    await Holiday.deleteOne({ _id: existing._id });
    return ok(res, { id: req.params.id }, 'Holiday deleted');
  } catch (e) {
    return fail(res, 500, 'Failed to delete holiday', e.message);
  }
});

module.exports = router;


