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

// PATCH /api/consultation/rating/:consultationId - Add rating and feedback
router.patch('/rating/:consultationId', consultationController.addConsultationRating);

// DELETE /api/consultation/:consultationId - Delete a consultation
router.delete('/:consultationId', consultationController.deleteConsultation);

module.exports = router;
