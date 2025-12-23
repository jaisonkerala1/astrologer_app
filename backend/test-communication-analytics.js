/**
 * Test Communication Analytics API Endpoints
 * Run with: node backend/test-communication-analytics.js
 */

const axios = require('axios');

const BASE_URL = 'https://astrologerapp-production.up.railway.app/api';
const ADMIN_KEY = 'admin123';

const headers = {
  'x-admin-key': ADMIN_KEY,
  'Content-Type': 'application/json',
};

async function testEndpoints() {
  console.log('🧪 Testing Communication Analytics Endpoints...\n');
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Admin Key: ${ADMIN_KEY}\n`);

  const tests = [
    {
      name: 'Overview Stats',
      endpoint: '/admin/communications/stats?period=7d',
    },
    {
      name: 'Trends (Daily)',
      endpoint: '/admin/communications/trends?period=7d',
    },
    {
      name: 'By Astrologer',
      endpoint: '/admin/communications/astrologers?period=7d',
    },
    {
      name: 'Call Duration',
      endpoint: '/admin/communications/call-duration?period=7d',
    },
    {
      name: 'Peak Hours',
      endpoint: '/admin/communications/peak-hours?period=7d',
    },
    {
      name: 'Success Rates',
      endpoint: '/admin/communications/success-rates?period=7d',
    },
  ];

  for (const test of tests) {
    try {
      console.log(`\n📊 Testing: ${test.name}`);
      console.log(`   Endpoint: ${test.endpoint}`);
      
      const response = await axios.get(`${BASE_URL}${test.endpoint}`, { headers });
      
      console.log(`   ✅ Status: ${response.status}`);
      console.log(`   ✅ Success: ${response.data.success}`);
      
      if (response.data.data) {
        if (Array.isArray(response.data.data)) {
          console.log(`   📦 Data: Array with ${response.data.data.length} items`);
          if (response.data.data.length > 0) {
            console.log(`   📋 Sample: ${JSON.stringify(response.data.data[0], null, 2)}`);
          }
        } else {
          console.log(`   📦 Data: ${JSON.stringify(response.data.data, null, 2)}`);
        }
      }
    } catch (error) {
      console.log(`   ❌ Error: ${error.response?.status || error.message}`);
      if (error.response?.data) {
        console.log(`   📋 Response: ${JSON.stringify(error.response.data, null, 2)}`);
      }
    }
  }

  console.log('\n\n✅ All tests completed!');
}

testEndpoints();
