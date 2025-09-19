const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:7566/api';
const ASTROLOGER_ID = '65f8b2c4d1234567890abcdef'; // Replace with actual astrologer ID

// Test data
const testConsultation = {
  clientName: 'Test Client',
  clientPhone: '+1234567890',
  clientEmail: 'test@example.com',
  scheduledTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
  duration: 30,
  amount: 500,
  type: 'phone',
  notes: 'Test consultation for API testing'
};

async function testConsultationAPI() {
  console.log('🧪 Starting Consultation API Tests...\n');

  try {
    // Test 1: Create Consultation
    console.log('1️⃣ Testing CREATE consultation...');
    const createResponse = await axios.post(
      `${BASE_URL}/consultation/${ASTROLOGER_ID}`,
      testConsultation
    );
    
    if (createResponse.data.success) {
      console.log('✅ Consultation created successfully');
      console.log('   ID:', createResponse.data.data._id);
      const consultationId = createResponse.data.data._id;
      
      // Test 2: Get Single Consultation
      console.log('\n2️⃣ Testing GET single consultation...');
      const getResponse = await axios.get(`${BASE_URL}/consultation/detail/${consultationId}`);
      
      if (getResponse.data.success) {
        console.log('✅ Consultation retrieved successfully');
        console.log('   Client:', getResponse.data.data.clientName);
      } else {
        console.log('❌ Failed to retrieve consultation');
      }

      // Test 3: Update Consultation
      console.log('\n3️⃣ Testing UPDATE consultation...');
      const updateData = {
        ...testConsultation,
        notes: 'Updated test consultation notes',
        amount: 750
      };
      
      const updateResponse = await axios.put(
        `${BASE_URL}/consultation/${consultationId}`,
        updateData
      );
      
      if (updateResponse.data.success) {
        console.log('✅ Consultation updated successfully');
        console.log('   New amount:', updateResponse.data.data.amount);
      } else {
        console.log('❌ Failed to update consultation');
      }

      // Test 4: Update Status
      console.log('\n4️⃣ Testing UPDATE status...');
      const statusResponse = await axios.patch(
        `${BASE_URL}/consultation/status/${consultationId}`,
        {
          status: 'completed',
          notes: 'Test consultation completed successfully'
        }
      );
      
      if (statusResponse.data.success) {
        console.log('✅ Consultation status updated successfully');
        console.log('   New status:', statusResponse.data.data.status);
      } else {
        console.log('❌ Failed to update consultation status');
      }

      // Test 5: Add Notes
      console.log('\n5️⃣ Testing ADD notes...');
      const notesResponse = await axios.patch(
        `${BASE_URL}/consultation/notes/${consultationId}`,
        {
          notes: 'Additional notes added via API test'
        }
      );
      
      if (notesResponse.data.success) {
        console.log('✅ Notes added successfully');
      } else {
        console.log('❌ Failed to add notes');
      }

      // Test 6: Add Rating
      console.log('\n6️⃣ Testing ADD rating...');
      const ratingResponse = await axios.patch(
        `${BASE_URL}/consultation/rating/${consultationId}`,
        {
          rating: 5,
          feedback: 'Excellent consultation service!'
        }
      );
      
      if (ratingResponse.data.success) {
        console.log('✅ Rating added successfully');
        console.log('   Rating:', ratingResponse.data.data.rating);
      } else {
        console.log('❌ Failed to add rating');
      }

    } else {
      console.log('❌ Failed to create consultation');
      console.log('   Error:', createResponse.data.message);
    }

    // Test 7: Get All Consultations
    console.log('\n7️⃣ Testing GET all consultations...');
    const getAllResponse = await axios.get(`${BASE_URL}/consultation/${ASTROLOGER_ID}`);
    
    if (getAllResponse.data.success) {
      console.log('✅ All consultations retrieved successfully');
      console.log('   Total consultations:', getAllResponse.data.data.pagination.totalItems);
    } else {
      console.log('❌ Failed to retrieve all consultations');
    }

    // Test 8: Get Upcoming Consultations
    console.log('\n8️⃣ Testing GET upcoming consultations...');
    const upcomingResponse = await axios.get(`${BASE_URL}/consultation/upcoming/${ASTROLOGER_ID}`);
    
    if (upcomingResponse.data.success) {
      console.log('✅ Upcoming consultations retrieved successfully');
      console.log('   Upcoming count:', upcomingResponse.data.data.length);
    } else {
      console.log('❌ Failed to retrieve upcoming consultations');
    }

    // Test 9: Get Today's Consultations
    console.log('\n9️⃣ Testing GET today\'s consultations...');
    const todayResponse = await axios.get(`${BASE_URL}/consultation/today/${ASTROLOGER_ID}`);
    
    if (todayResponse.data.success) {
      console.log('✅ Today\'s consultations retrieved successfully');
      console.log('   Today\'s count:', todayResponse.data.data.length);
    } else {
      console.log('❌ Failed to retrieve today\'s consultations');
    }

    // Test 10: Get Statistics
    console.log('\n🔟 Testing GET statistics...');
    const statsResponse = await axios.get(`${BASE_URL}/consultation/stats/${ASTROLOGER_ID}`);
    
    if (statsResponse.data.success) {
      console.log('✅ Statistics retrieved successfully');
      console.log('   Total earnings:', statsResponse.data.data.totalEarnings);
      console.log('   Status breakdown:', statsResponse.data.data.stats);
    } else {
      console.log('❌ Failed to retrieve statistics');
    }

    console.log('\n🎉 All API tests completed!');

  } catch (error) {
    console.error('\n❌ API Test Error:', error.message);
    
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    } else if (error.request) {
      console.error('   Network Error: Could not connect to server');
      console.error('   Make sure the backend server is running on port 7566');
    }
  }
}

// Helper function to test with different consultation types
async function testDifferentConsultationTypes() {
  console.log('\n🔍 Testing different consultation types...\n');

  const consultationTypes = ['phone', 'video', 'inPerson', 'chat'];
  
  for (const type of consultationTypes) {
    try {
      const consultation = {
        ...testConsultation,
        clientName: `Test Client - ${type}`,
        type: type,
        amount: type === 'inPerson' ? 1000 : 500
      };

      console.log(`Testing ${type} consultation...`);
      
      const response = await axios.post(
        `${BASE_URL}/consultation/${ASTROLOGER_ID}`,
        consultation
      );
      
      if (response.data.success) {
        console.log(`✅ ${type} consultation created successfully`);
      } else {
        console.log(`❌ Failed to create ${type} consultation`);
      }
      
    } catch (error) {
      console.error(`❌ Error testing ${type} consultation:`, error.message);
    }
  }
}

// Helper function to test error handling
async function testErrorHandling() {
  console.log('\n🚨 Testing error handling...\n');

  try {
    // Test with invalid astrologer ID
    console.log('Testing with invalid astrologer ID...');
    const invalidResponse = await axios.post(
      `${BASE_URL}/consultation/invalid_id`,
      testConsultation
    );
    console.log('❌ Should have failed with invalid ID');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Properly handled invalid astrologer ID');
    } else {
      console.log('❌ Unexpected error handling');
    }
  }

  try {
    // Test with past scheduled time
    console.log('\nTesting with past scheduled time...');
    const pastConsultation = {
      ...testConsultation,
      clientName: 'Past Time Test',
      scheduledTime: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString() // Yesterday
    };
    
    const pastResponse = await axios.post(
      `${BASE_URL}/consultation/${ASTROLOGER_ID}`,
      pastConsultation
    );
    console.log('❌ Should have failed with past time');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Properly handled past scheduled time');
    } else {
      console.log('❌ Unexpected error handling');
    }
  }

  try {
    // Test with missing required fields
    console.log('\nTesting with missing required fields...');
    const incompleteConsultation = {
      clientName: 'Incomplete Test'
      // Missing required fields
    };
    
    const incompleteResponse = await axios.post(
      `${BASE_URL}/consultation/${ASTROLOGER_ID}`,
      incompleteConsultation
    );
    console.log('❌ Should have failed with missing fields');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Properly handled missing required fields');
    } else {
      console.log('❌ Unexpected error handling');
    }
  }
}

// Run all tests
async function runAllTests() {
  await testConsultationAPI();
  await testDifferentConsultationTypes();
  await testErrorHandling();
  
  console.log('\n✨ All tests completed!');
  console.log('\n📋 Next steps:');
  console.log('1. Check MongoDB for created consultations');
  console.log('2. Test the Flutter app integration');
  console.log('3. Verify real-time updates work correctly');
  console.log('4. Test offline/online synchronization');
}

// Check if axios is available
try {
  require('axios');
} catch (error) {
  console.error('❌ axios is required to run this test script');
  console.log('Install it with: npm install axios');
  process.exit(1);
}

// Run tests if this file is executed directly
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  testConsultationAPI,
  testDifferentConsultationTypes,
  testErrorHandling,
  runAllTests
};
