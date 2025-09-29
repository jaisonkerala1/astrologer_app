const express = require('express');
const router = express.Router();
const migrateBioFields = require('../scripts/migrateBioFields');

// @route   POST /api/migration/bio-fields
// @desc    Migrate existing astrologers to include bio fields
// @access  Public (for migration purposes)
router.post('/bio-fields', async (req, res) => {
  try {
    console.log('Starting bio fields migration via API...');
    await migrateBioFields();
    
    res.json({
      success: true,
      message: 'Bio fields migration completed successfully'
    });
  } catch (error) {
    console.error('Migration API error:', error);
    res.status(500).json({
      success: false,
      message: 'Migration failed',
      error: error.message
    });
  }
});

module.exports = router;
