// Quick test script to create a test ticket for the admin dashboard
const axios = require('axios');

const BASE_URL = 'https://astrologerapp-production.up.railway.app/api/support';

// Replace with a valid JWT token from your astrologer app
const AUTH_TOKEN = 'YOUR_JWT_TOKEN_HERE';

async function createTestTicket() {
  try {
    console.log('🎫 Creating test ticket...');
    
    const response = await axios.post(
      `${BASE_URL}/tickets`,
      {
        title: 'Test Ticket from Admin Dashboard',
        description: 'This is a test ticket created to verify the admin dashboard support system is working correctly.',
        category: 'Technical Support',
        priority: 'Medium',
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AUTH_TOKEN}`,
        },
      }
    );

    console.log('✅ Test ticket created successfully!');
    console.log('📝 Ticket ID:', response.data.data._id);
    console.log('🔢 Ticket Number:', response.data.data.ticketNumber);
    console.log('\n🎯 Now check the admin dashboard at:');
    console.log('   https://astrologer-admin-dashboard.vercel.app/support');
  } catch (error) {
    if (error.response) {
      console.error('❌ Error creating ticket:', error.response.status, error.response.data);
    } else {
      console.error('❌ Error:', error.message);
    }
  }
}

// Run the test
createTestTicket();









