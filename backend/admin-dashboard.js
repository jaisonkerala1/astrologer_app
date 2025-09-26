const API_BASE = 'https://astrologerapp-production.up.railway.app/api';

async function refreshData() {
    document.getElementById('loading').style.display = 'block';
    document.getElementById('error').style.display = 'none';
    document.getElementById('stats').style.display = 'none';
    document.getElementById('streamsContainer').style.display = 'none';
    document.getElementById('noStreams').style.display = 'none';

    try {
        console.log('Fetching data from:', `${API_BASE}/live-streams/status`);
        const response = await fetch(`${API_BASE}/live-streams/status`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
            mode: 'cors'
        });
        
        console.log('Response status:', response.status);
        console.log('Response headers:', response.headers);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Response data:', data);

        if (data.success) {
            displayData(data.data);
        } else {
            throw new Error(data.message || 'Failed to fetch data');
        }
    } catch (error) {
        console.error('Error fetching data:', error);
        document.getElementById('loading').style.display = 'none';
        document.getElementById('error').style.display = 'block';
        document.getElementById('error').textContent = `Error: ${error.message}`;
    }
}

function displayData(data) {
    document.getElementById('loading').style.display = 'none';
    
    // Update stats
    document.getElementById('totalStreams').textContent = data.totalActiveStreams;
    document.getElementById('totalViewers').textContent = data.streams.reduce((sum, stream) => sum + stream.viewerCount, 0);
    document.getElementById('serverUptime').textContent = formatUptime(data.uptime);
    document.getElementById('stats').style.display = 'grid';

    // Update streams table
    const tbody = document.getElementById('streamsTableBody');
    tbody.innerHTML = '';

    if (data.streams.length === 0) {
        document.getElementById('noStreams').style.display = 'block';
    } else {
        document.getElementById('streamsContainer').style.display = 'block';
        
        data.streams.forEach(stream => {
            const row = tbody.insertRow();
            row.innerHTML = `
                <td>${stream.id}</td>
                <td>${stream.astrologerName}</td>
                <td>${stream.title}</td>
                <td><span class="status-${stream.status}">${stream.status.toUpperCase()}</span></td>
                <td>${stream.channelName}</td>
                <td>${stream.viewerCount}</td>
                <td>${formatDuration(stream.duration)}</td>
                <td>${new Date(stream.startedAt).toLocaleString()}</td>
            `;
        });
    }
}

function formatUptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
}

function formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

// Test API function
async function testAPI() {
    try {
        console.log('Testing API endpoints...');
        
        // Test health endpoint
        const healthResponse = await fetch(`${API_BASE}/health`);
        const healthData = await healthResponse.json();
        console.log('Health check:', healthData);
        
        // Test live streams endpoint
        const streamsResponse = await fetch(`${API_BASE}/live-streams/status`);
        const streamsData = await streamsResponse.json();
        console.log('Live streams:', streamsData);
        
        alert(`API Test Results:\n\nHealth: ${healthData.status}\nStreams: ${streamsData.success ? 'Success' : 'Failed'}\nActive Streams: ${streamsData.data?.totalActiveStreams || 0}\n\nCheck browser console for details.`);
        
    } catch (error) {
        console.error('API Test Error:', error);
        alert(`API Test Failed: ${error.message}`);
    }
}

// Auto-refresh every 10 seconds
setInterval(refreshData, 10000);

// Load data on page load
document.addEventListener('DOMContentLoaded', function() {
    refreshData();
});
