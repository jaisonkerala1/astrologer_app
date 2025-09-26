let currentChannel = '';
let pollingInterval = null;

// Show message to user
function showMessage(message, type = 'info') {
    const messageDiv = document.getElementById('message');
    messageDiv.textContent = message;
    messageDiv.className = type;
    messageDiv.style.display = 'block';
    
    if (type === 'success' || type === 'error') {
        setTimeout(() => {
            messageDiv.style.display = 'none';
        }, 5000);
    }
}

// Update stream information
function updateStreamInfo(stream) {
    document.getElementById('channelName').textContent = stream.channelName;
    document.getElementById('streamStatus').textContent = stream.status.toUpperCase();
    document.getElementById('viewerCount').textContent = stream.viewerCount;
    document.getElementById('duration').textContent = formatDuration(stream.duration);
    document.getElementById('streamInfo').style.display = 'block';
    
    // Update current channel display
    document.getElementById('currentChannel').textContent = stream.channelName;
    document.getElementById('channelInput').value = stream.channelName;
}

// Format duration
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

// Open Agora Web Demo
function openAgoraDemo() {
    const channelName = document.getElementById('channelInput').value.trim();
    if (!channelName) {
        showMessage('Please enter a channel name', 'error');
        return;
    }
    
    // Try multiple Agora demo URLs
    const demoUrls = [
        `https://webdemo.agora.io/agora-web-showcase/?channel=${channelName}`,
        `https://demo.agora.io/en/video-call/?channel=${channelName}`,
        `https://webdemo.agora.io/agora-web-showcase/`
    ];
    
    // Try to open the first URL
    const newWindow = window.open(demoUrls[0], '_blank');
    
    if (!newWindow) {
        // If popup blocked, show instructions
        showMessage('Popup blocked! Please manually open: ' + demoUrls[0], 'error');
    } else {
        showMessage('Opening Agora Web Demo...', 'success');
    }
}

// Copy channel name to clipboard
function copyChannelName() {
    const channelName = document.getElementById('channelInput').value.trim();
    if (!channelName) {
        showMessage('No channel name to copy', 'error');
        return;
    }
    
    navigator.clipboard.writeText(channelName).then(() => {
        showMessage('Channel name copied to clipboard!', 'success');
    }).catch(() => {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = channelName;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        showMessage('Channel name copied to clipboard!', 'success');
    });
}

// Poll for stream updates
function startPolling() {
    if (pollingInterval) return;
    
    pollingInterval = setInterval(() => {
        fetch('https://astrologerapp-production.up.railway.app/api/live-streams/status')
            .then(response => response.json())
            .then(data => {
                if (data.success && data.data.streams.length > 0) {
                    const stream = data.data.streams[0];
                    updateStreamInfo(stream);
                    currentChannel = stream.channelName;
                    
                    // Update status
                    document.getElementById('status').textContent = 
                        `Live stream active: ${stream.astrologerName} - ${stream.title}`;
                } else {
                    document.getElementById('status').textContent = 'No active streams found';
                    document.getElementById('streamInfo').style.display = 'none';
                }
            })
            .catch(error => {
                console.error('Error polling streams:', error);
                document.getElementById('status').textContent = 'Error connecting to server';
            });
    }, 3000);
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Add event listeners
    document.getElementById('openDemoBtn').addEventListener('click', openAgoraDemo);
    document.getElementById('copyChannelBtn').addEventListener('click', copyChannelName);
    
    // Start polling for streams
    startPolling();
    
    // Initial load
    fetch('https://astrologerapp-production.up.railway.app/api/live-streams/status')
        .then(response => response.json())
        .then(data => {
            if (data.success && data.data.streams.length > 0) {
                const stream = data.data.streams[0];
                updateStreamInfo(stream);
                currentChannel = stream.channelName;
                showMessage('Live stream detected! Click "Open Agora Web Demo" to watch.', 'success');
            } else {
                showMessage('No active streams found. Start a live stream from your mobile app.', 'error');
            }
        })
        .catch(error => {
            console.error('Error fetching streams:', error);
            showMessage('Error connecting to server. Please try again.', 'error');
        });
});
