const axios = require('axios');

const API_BASE = 'https://astrologerapp-production.up.railway.app/api';

async function testLiveStreams() {
    console.log('🧪 Testing Live Streams API...\n');

    try {
        // Test 1: Health check
        console.log('1️⃣ Testing server health...');
        const healthResponse = await axios.get(`${API_BASE}/health`);
        console.log('✅ Server is healthy:', healthResponse.data);
        console.log('');

        // Test 2: Get live streams status
        console.log('2️⃣ Getting live streams status...');
        const statusResponse = await axios.get(`${API_BASE}/live-streams/status`);
        console.log('✅ Live streams status:', JSON.stringify(statusResponse.data, null, 2));
        console.log('');

        // Test 3: Get admin data
        console.log('3️⃣ Getting admin live streams data...');
        const adminResponse = await axios.get(`${API_BASE}/admin/live-streams`);
        console.log('✅ Admin data:', JSON.stringify(adminResponse.data, null, 2));
        console.log('');

        // Test 4: Test starting a mock stream
        console.log('4️⃣ Testing stream start (mock)...');
        const mockStreamData = {
            astrologerId: 'test_astrologer_123',
            astrologerName: 'Test Astrologer',
            astrologerProfilePicture: null,
            title: 'Test Live Stream - ' + new Date().toLocaleTimeString(),
            description: 'This is a test stream for debugging',
            category: 'astrology',
            quality: 'medium',
            isPrivate: false,
            tags: ['test', 'debug'],
            agoraChannelName: 'test_channel_' + Date.now(),
            agoraToken: null
        };

        const startResponse = await axios.post(`${API_BASE}/live-streams/start`, mockStreamData);
        console.log('✅ Stream started:', JSON.stringify(startResponse.data, null, 2));
        console.log('');

        // Wait a moment
        console.log('⏳ Waiting 3 seconds...');
        await new Promise(resolve => setTimeout(resolve, 3000));

        // Test 5: Check status again
        console.log('5️⃣ Checking status after stream start...');
        const statusResponse2 = await axios.get(`${API_BASE}/live-streams/status`);
        console.log('✅ Updated status:', JSON.stringify(statusResponse2.data, null, 2));
        console.log('');

        // Test 6: End the test stream
        if (startResponse.data.success && startResponse.data.data) {
            console.log('6️⃣ Ending test stream...');
            const endResponse = await axios.put(`${API_BASE}/live-streams/${startResponse.data.data.id}/end`);
            console.log('✅ Stream ended:', JSON.stringify(endResponse.data, null, 2));
            console.log('');
        }

        console.log('🎉 All tests completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Headers:', error.response.headers);
        }
    }
}

// Run the test
testLiveStreams();
