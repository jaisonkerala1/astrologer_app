const mongoose = require('mongoose');
require('dotenv').config();

// Import the Astrologer model
const Astrologer = require('../models/Astrologer');

// Sample response time data
const sampleResponseTimes = [
  { consultationType: 'call', responseTime: 2.5 },
  { consultationType: 'video', responseTime: 1.8 },
  { consultationType: 'chat', responseTime: 0.5 },
  { consultationType: 'call', responseTime: 3.2 },
  { consultationType: 'video', responseTime: 2.1 },
  { consultationType: 'chat', responseTime: 0.8 },
  { consultationType: 'in_person', responseTime: 5.0 },
  { consultationType: 'call', responseTime: 1.9 },
  { consultationType: 'video', responseTime: 2.8 },
  { consultationType: 'chat', responseTime: 0.3 },
  { consultationType: 'call', responseTime: 4.1 },
  { consultationType: 'video', responseTime: 1.5 },
  { consultationType: 'chat', responseTime: 0.7 },
  { consultationType: 'in_person', responseTime: 3.5 },
  { consultationType: 'call', responseTime: 2.3 },
  { consultationType: 'video', responseTime: 2.9 },
  { consultationType: 'chat', responseTime: 0.4 },
  { consultationType: 'call', responseTime: 1.7 },
  { consultationType: 'video', responseTime: 3.1 },
  { consultationType: 'chat', responseTime: 0.6 }
];

// Generate consultation IDs
const generateConsultationId = () => {
  return 'consult_' + Math.random().toString(36).substr(2, 9);
};

// Generate timestamps for the last 30 days
const generateTimestamps = (count) => {
  const timestamps = [];
  const now = new Date();
  
  for (let i = 0; i < count; i++) {
    const daysAgo = Math.floor(Math.random() * 30);
    const hoursAgo = Math.floor(Math.random() * 24);
    const minutesAgo = Math.floor(Math.random() * 60);
    
    const timestamp = new Date(now);
    timestamp.setDate(timestamp.getDate() - daysAgo);
    timestamp.setHours(timestamp.getHours() - hoursAgo);
    timestamp.setMinutes(timestamp.getMinutes() - minutesAgo);
    
    timestamps.push(timestamp);
  }
  
  return timestamps.sort((a, b) => a - b);
};

const seedResponseTimeData = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log('Connected to MongoDB for response time seeding');

    // Get all astrologers
    const astrologers = await Astrologer.find({});
    console.log(`Found ${astrologers.length} astrologers`);

    if (astrologers.length === 0) {
      console.log('No astrologers found. Please seed astrologers first.');
      return;
    }

    // Seed response time data for each astrologer
    for (const astrologer of astrologers) {
      console.log(`Seeding response time data for astrologer: ${astrologer.name}`);
      
      // Clear existing response time data
      astrologer.responseTimeStats = {
        averageResponseTime: 0,
        totalResponses: 0,
        lastUpdated: new Date(),
        responseTimeHistory: []
      };

      // Generate random number of response times (5-20 per astrologer)
      const responseCount = Math.floor(Math.random() * 16) + 5;
      const timestamps = generateTimestamps(responseCount);
      
      // Add response time entries
      for (let i = 0; i < responseCount; i++) {
        const sampleData = sampleResponseTimes[Math.floor(Math.random() * sampleResponseTimes.length)];
        const consultationId = generateConsultationId();
        
        // Add some variation to response times
        const variation = (Math.random() - 0.5) * 2; // -1 to +1 minutes
        const responseTime = Math.max(0.1, sampleData.responseTime + variation);
        
        astrologer.responseTimeStats.responseTimeHistory.push({
          consultationId,
          responseTime: Math.round(responseTime * 10) / 10, // Round to 1 decimal
          consultationType: sampleData.consultationType,
          timestamp: timestamps[i]
        });
      }

      // Calculate statistics
      const history = astrologer.responseTimeStats.responseTimeHistory;
      astrologer.responseTimeStats.totalResponses = history.length;
      
      if (history.length > 0) {
        const totalTime = history.reduce((sum, entry) => sum + entry.responseTime, 0);
        astrologer.responseTimeStats.averageResponseTime = Math.round((totalTime / history.length) * 10) / 10;
      }
      
      astrologer.responseTimeStats.lastUpdated = new Date();
      
      // Save the astrologer
      await astrologer.save();
      
      console.log(`  - Added ${history.length} response time entries`);
      console.log(`  - Average response time: ${astrologer.responseTimeStats.averageResponseTime} minutes`);
    }

    console.log('Response time data seeded successfully!');
    
    // Display summary
    const updatedAstrologers = await Astrologer.find({});
    console.log('\n=== Response Time Summary ===');
    updatedAstrologers.forEach(astrologer => {
      const stats = astrologer.getResponseTimeStats();
      console.log(`${astrologer.name}:`);
      console.log(`  - Average Response Time: ${stats.averageResponseTime} minutes`);
      console.log(`  - Total Responses: ${stats.totalResponses}`);
      console.log(`  - Min Response Time: ${stats.minResponseTime} minutes`);
      console.log(`  - Max Response Time: ${stats.maxResponseTime} minutes`);
      console.log(`  - By Type:`, stats.byConsultationType);
      console.log('');
    });

  } catch (error) {
    console.error('Error seeding response time data:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

// Run the seeding function
if (require.main === module) {
  seedResponseTimeData();
}

module.exports = seedResponseTimeData;
