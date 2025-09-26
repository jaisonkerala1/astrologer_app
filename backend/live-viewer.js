let isJoined = false;
let currentChannel = '';

// Auto-fill with your current stream channel
document.addEventListener('DOMContentLoaded', function() {
    // Get current active streams
    fetch('https://astrologerapp-production.up.railway.app/api/live-streams/status')
        .then(response => response.json())
        .then(data => {
            if (data.success && data.data.streams.length > 0) {
                const stream = data.data.streams[0];
                document.getElementById('channelInput').value = stream.channelName;
                updateStreamInfo(stream);
            }
        })
        .catch(error => {
            console.error('Error fetching streams:', error);
        });

    // Add event listeners
    document.getElementById('joinBtn').addEventListener('click', joinChannel);
    document.getElementById('leaveBtn').addEventListener('click', leaveChannel);
});

function updateStreamInfo(stream) {
    document.getElementById('channelName').textContent = stream.channelName;
    document.getElementById('streamStatus').textContent = stream.status.toUpperCase();
    document.getElementById('viewerCount').textContent = stream.viewerCount;
    document.getElementById('streamInfo').style.display = 'block';
}

function joinChannel() {
    const channelName = document.getElementById('channelInput').value.trim();
    if (!channelName) {
        alert('Please enter a channel name');
        return;
    }

    currentChannel = channelName;
    document.getElementById('status').textContent = 'Joining channel: ' + channelName;
    document.getElementById('joinBtn').disabled = true;
    document.getElementById('leaveBtn').disabled = false;

    // For now, show a placeholder since we need Agora SDK
    document.getElementById('video-player').innerHTML = `
        <div style="text-align: center;">
            <h3>🎥 Live Stream: ${channelName}</h3>
            <p>To view the actual video, you need to integrate Agora Web SDK</p>
            <p>For now, you can use the Agora Web Demo:</p>
            <a href="https://webdemo.agora.io/agora-web-showcase/" target="_blank" style="color: #007bff;">
                Open Agora Web Demo
            </a>
            <br><br>
            <p>Channel Name: <strong>${channelName}</strong></p>
        </div>
    `;

    isJoined = true;
    document.getElementById('status').textContent = 'Connected to channel: ' + channelName;

    // Start polling for stream updates
    startPolling();
}

function leaveChannel() {
    document.getElementById('video-player').innerHTML = '<div>Enter channel name and click "Join Stream" to watch</div>';
    document.getElementById('joinBtn').disabled = false;
    document.getElementById('leaveBtn').disabled = true;
    document.getElementById('status').textContent = 'Disconnected from channel';
    isJoined = false;
    currentChannel = '';
}

function startPolling() {
    if (!isJoined) return;

    // Poll for stream updates every 5 seconds
    setInterval(() => {
        if (isJoined) {
            fetch('https://astrologerapp-production.up.railway.app/api/live-streams/status')
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.data.streams.length > 0) {
                        const stream = data.data.streams.find(s => s.channelName === currentChannel);
                        if (stream) {
                            updateStreamInfo(stream);
                        }
                    }
                })
                .catch(error => {
                    console.error('Error polling streams:', error);
                });
        }
    }, 5000);
}
