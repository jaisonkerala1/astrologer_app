// Agora configuration
const APP_ID = '6358473261094f98be1fea84042b1fcf';
let client = null;
let isJoined = false;
let currentChannel = '';

// Initialize Agora client
function initAgora() {
    try {
        client = AgoraRTC.createClient({ mode: "live", codec: "vp8" });
        console.log('Agora client initialized');
        return true;
    } catch (error) {
        console.error('Failed to initialize Agora client:', error);
        showMessage('Failed to initialize video engine: ' + error.message, 'error');
        return false;
    }
}

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
    document.getElementById('streamInfo').style.display = 'block';
}

// Join channel
async function joinChannel() {
    const channelName = document.getElementById('channelInput').value.trim();
    if (!channelName) {
        showMessage('Please enter a channel name', 'error');
        return;
    }

    if (!client) {
        if (!initAgora()) {
            return;
        }
    }

    try {
        currentChannel = channelName;
        document.getElementById('status').textContent = 'Joining channel: ' + channelName;
        document.getElementById('joinBtn').disabled = true;
        document.getElementById('leaveBtn').disabled = false;

        // Set up event handlers
        client.on("user-published", handleUserPublished);
        client.on("user-unpublished", handleUserUnpublished);
        client.on("user-joined", handleUserJoined);
        client.on("user-left", handleUserLeft);

        // Join as audience
        await client.join(APP_ID, channelName, null, null);
        
        document.getElementById('status').textContent = 'Connected to channel: ' + channelName;
        showMessage('Successfully joined channel: ' + channelName, 'success');
        
        isJoined = true;
        
        // Start polling for stream updates
        startPolling();

    } catch (error) {
        console.error('Failed to join channel:', error);
        showMessage('Failed to join channel: ' + error.message, 'error');
        document.getElementById('joinBtn').disabled = false;
        document.getElementById('leaveBtn').disabled = true;
    }
}

// Leave channel
async function leaveChannel() {
    if (!client || !isJoined) return;

    try {
        await client.leave();
        
        document.getElementById('video-player').innerHTML = '<div>Enter channel name and click "Join Stream" to watch</div>';
        document.getElementById('joinBtn').disabled = false;
        document.getElementById('leaveBtn').disabled = true;
        document.getElementById('status').textContent = 'Disconnected from channel';
        showMessage('Left channel successfully', 'success');
        
        isJoined = false;
        currentChannel = '';

    } catch (error) {
        console.error('Failed to leave channel:', error);
        showMessage('Failed to leave channel: ' + error.message, 'error');
    }
}

// Handle user published (stream started)
async function handleUserPublished(user, mediaType) {
    console.log('User published:', user.uid, mediaType);
    
    try {
        await client.subscribe(user, mediaType);
        
        if (mediaType === "video") {
            const remoteVideoTrack = user.videoTrack;
            const remotePlayerContainer = document.getElementById('video-player');
            
            // Clear previous content
            remotePlayerContainer.innerHTML = '';
            
            // Create video element
            const videoElement = document.createElement('div');
            videoElement.id = `remote-video-${user.uid}`;
            videoElement.style.width = '100%';
            videoElement.style.height = '100%';
            videoElement.style.background = '#000';
            
            remotePlayerContainer.appendChild(videoElement);
            
            // Play the remote video
            remoteVideoTrack.play(videoElement);
            
            showMessage('Live video stream started!', 'success');
        }
        
        if (mediaType === "audio") {
            const remoteAudioTrack = user.audioTrack;
            remoteAudioTrack.play();
        }
        
    } catch (error) {
        console.error('Failed to subscribe to user:', error);
        showMessage('Failed to load video stream: ' + error.message, 'error');
    }
}

// Handle user unpublished (stream ended)
function handleUserUnpublished(user, mediaType) {
    console.log('User unpublished:', user.uid, mediaType);
    
    if (mediaType === "video") {
        const remotePlayerContainer = document.getElementById('video-player');
        const videoElement = document.getElementById(`remote-video-${user.uid}`);
        if (videoElement) {
            videoElement.remove();
        }
        
        if (remotePlayerContainer.children.length === 0) {
            remotePlayerContainer.innerHTML = '<div>No video stream available</div>';
        }
    }
}

// Handle user joined
function handleUserJoined(user) {
    console.log('User joined:', user.uid);
    showMessage('User joined: ' + user.uid, 'success');
}

// Handle user left
function handleUserLeft(user) {
    console.log('User left:', user.uid);
    showMessage('User left: ' + user.uid, 'success');
}

// Poll for stream updates
function startPolling() {
    if (!isJoined) return;

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

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Agora
    initAgora();
    
    // Add event listeners
    document.getElementById('joinBtn').addEventListener('click', joinChannel);
    document.getElementById('leaveBtn').addEventListener('click', leaveChannel);
    
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
});
