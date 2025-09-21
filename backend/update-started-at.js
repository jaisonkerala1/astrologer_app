const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/astrologer_app', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const Consultation = require('./src/models/Consultation');

async function updateStartedAt() {
  try {
    console.log('Starting update of startedAt fields...');
    
    // Find all consultations with status 'inProgress' that don't have startedAt
    const consultations = await Consultation.find({
      status: 'inProgress',
      startedAt: { $exists: false }
    });
    
    console.log(`Found ${consultations.length} in-progress consultations without startedAt`);
    
    // Update each consultation with a startedAt timestamp
    for (const consultation of consultations) {
      // Set startedAt to the updatedAt time (when status was changed to inProgress)
      const startedAt = consultation.updatedAt || new Date();
      
      await Consultation.findByIdAndUpdate(consultation._id, {
        startedAt: startedAt
      });
      
      console.log(`Updated consultation ${consultation._id} with startedAt: ${startedAt}`);
    }
    
    console.log('Successfully updated all in-progress consultations with startedAt');
    
    // Verify the updates
    const updatedConsultations = await Consultation.find({
      status: 'inProgress'
    }).select('_id clientName status startedAt updatedAt');
    
    console.log('\nVerification - All in-progress consultations:');
    updatedConsultations.forEach(consultation => {
      console.log(`ID: ${consultation._id}, Client: ${consultation.clientName}, Status: ${consultation.status}, StartedAt: ${consultation.startedAt}, UpdatedAt: ${consultation.updatedAt}`);
    });
    
  } catch (error) {
    console.error('Error updating startedAt fields:', error);
  } finally {
    mongoose.connection.close();
  }
}

updateStartedAt();
