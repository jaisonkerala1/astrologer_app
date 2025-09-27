const express = require('express');
const router = express.Router();
const consultationController = require('../controllers/consultationController');
const auth = require('../middleware/auth');

// Apply authentication middleware to all routes
router.use(auth);

// GET /api/consultation/:astrologerId - Get all consultations for an astrologer
router.get('/:astrologerId', consultationController.getConsultations);

// GET /api/consultation/upcoming/:astrologerId - Get upcoming consultations
router.get('/upcoming/:astrologerId', consultationController.getUpcomingConsultations);

// GET /api/consultation/today/:astrologerId - Get today's consultations
router.get('/today/:astrologerId', consultationController.getTodaysConsultations);

// GET /api/consultation/stats/:astrologerId - Get consultation statistics
router.get('/stats/:astrologerId', consultationController.getConsultationStats);

// GET /api/consultation/stats/:astrologerId/weekly - Get weekly consultation statistics
router.get('/stats/:astrologerId/weekly', consultationController.getWeeklyConsultationStats);

// GET /api/consultation/stats/:astrologerId/monthly - Get monthly consultation statistics
router.get('/stats/:astrologerId/monthly', consultationController.getMonthlyConsultationStats);

// GET /api/consultation/stats/:astrologerId/all-time - Get all-time consultation statistics
router.get('/stats/:astrologerId/all-time', consultationController.getAllTimeConsultationStats);

// GET /api/consultation/weekly/:astrologerId - Get weekly consultations
router.get('/weekly/:astrologerId', consultationController.getWeeklyConsultations);

// GET /api/consultation/monthly/:astrologerId - Get monthly consultations
router.get('/monthly/:astrologerId', consultationController.getMonthlyConsultations);

// GET /api/consultation/all-time/:astrologerId - Get all-time consultations
router.get('/all-time/:astrologerId', consultationController.getAllTimeConsultations);

 // POST /api/consultation/fix-started-at - Fix startedAt for existing consultations
router.post('/fix-started-at', consultationController.fixStartedAt);

// GET /api/consultation/detail/:consultationId - Get a single consultation by ID
router.get('/detail/:consultationId', consultationController.getConsultationById);

// POST /api/consultation/:astrologerId - Create a new consultation
router.post('/:astrologerId', consultationController.createConsultation);

// PUT /api/consultation/:consultationId - Update a consultation
router.put('/:consultationId', consultationController.updateConsultation);

// PATCH /api/consultation/status/:consultationId - Update consultation status
router.patch('/status/:consultationId', consultationController.updateConsultationStatus);

// PATCH /api/consultation/notes/:consultationId - Add notes to consultation
router.patch('/notes/:consultationId', consultationController.addConsultationNotes);

// PATCH /api/consultation/rating/:consultationId - Add rating and feedback (from clients)
router.patch('/rating/:consultationId', consultationController.addConsultationRating);

// PATCH /api/consultation/astrologer-rating/:consultationId - Add astrologer rating
router.patch('/astrologer-rating/:consultationId', consultationController.addAstrologerRating);

// PATCH /api/consultation/share/:consultationId - Track consultation share
router.patch('/share/:consultationId', consultationController.trackConsultationShare);

// PATCH /api/consultation/reschedule/:consultationId - Reschedule consultation
router.patch('/reschedule/:consultationId', consultationController.rescheduleConsultation);

// DELETE /api/consultation/:consultationId - Delete a consultation
router.delete('/:consultationId', consultationController.deleteConsultation);

module.exports = router;
