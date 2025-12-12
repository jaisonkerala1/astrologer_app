const express = require('express');
const router = express.Router();
const LiveStream = require('../models/LiveStream');
const Astrologer = require('../models/Astrologer');
const auth = require('../middleware/auth');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// Agora credentials from environment
const AGORA_APP_ID = process.env.AGORA_APP_ID;
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

/**
 * Generate Agora RTC Token
 * POST /api/live/agora-token
 */
router.post('/agora-token', auth, async (req, res) => {
  try {
    const { channelName, uid = 0, role = 'publisher' } = req.body;

    if (!channelName) {
      return res.status(400).json({
        success: false,
        message: 'Channel name is required'
      });
    }

    if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
      console.error('Agora credentials not configured');
      return res.status(500).json({
        success: false,
        message: 'Agora not configured on server'
      });
    }

    // Determine role
    const rtcRole = role === 'publisher' 
      ? RtcRole.PUBLISHER 
      : RtcRole.SUBSCRIBER;

    // Token expires in 24 hours
    const expireTime = 86400;
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTime + expireTime;

    // Generate token
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      rtcRole,
      privilegeExpireTime,
      privilegeExpireTime
    );

    console.log(`✅ Generated Agora token for channel: ${channelName}, role: ${role}`);

    res.json({
      success: true,
      data: {
        token,
        channelName,
        uid,
        appId: AGORA_APP_ID,
        expiresAt: new Date(privilegeExpireTime * 1000).toISOString()
      }
    });

  } catch (error) {
    console.error('Error generating Agora token:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate token',
      error: error.message
    });
  }
});

/**
 * Start a live stream
 * POST /api/live/start
 */
router.post('/start', auth, async (req, res) => {
  try {
    const astrologerId = req.user.id;
    const { title, description, category, tags } = req.body;

    // Get astrologer details
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    // Check if already live
    const existingStream = await LiveStream.findOne({
      astrologerId,
      isLive: true
    });

    if (existingStream) {
      return res.status(400).json({
        success: false,
        message: 'You already have an active live stream'
      });
    }

    // Create channel name
    const channelName = `live_${astrologerId}`;

    // Create live stream record
    const liveStream = new LiveStream({
      astrologerId,
      astrologerName: astrologer.name,
      astrologerProfilePicture: astrologer.profilePicture,
      astrologerSpecialty: astrologer.specialization?.[0] || 'Astrology',
      title: title || 'Live Session',
      description: description || '',
      category: category || 'astrology',
      tags: tags || [],
      agoraChannelName: channelName,
      isLive: true,
      startedAt: new Date()
    });

    await liveStream.save();

    // Generate token for broadcaster
    let token = '';
    if (AGORA_APP_ID && AGORA_APP_CERTIFICATE) {
      const expireTime = 86400;
      const currentTime = Math.floor(Date.now() / 1000);
      const privilegeExpireTime = currentTime + expireTime;

      token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        0,
        RtcRole.PUBLISHER,
        privilegeExpireTime,
        privilegeExpireTime
      );
    }

    console.log(`🔴 Live stream started: ${channelName} by ${astrologer.name}`);

    res.json({
      success: true,
      data: {
        ...liveStream.toObject(),
        agoraToken: token,
        appId: AGORA_APP_ID
      }
    });

  } catch (error) {
    console.error('Error starting live stream:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start live stream',
      error: error.message
    });
  }
});

/**
 * End a live stream
 * POST /api/live/:streamId/end
 */
router.post('/:streamId/end', auth, async (req, res) => {
  try {
    const { streamId } = req.params;
    const astrologerId = req.user.id;

    const liveStream = await LiveStream.findOne({
      _id: streamId,
      astrologerId
    });

    if (!liveStream) {
      return res.status(404).json({
        success: false,
        message: 'Live stream not found'
      });
    }

    liveStream.isLive = false;
    liveStream.endedAt = new Date();
    await liveStream.save();

    console.log(`⬛ Live stream ended: ${liveStream.agoraChannelName}`);

    res.json({
      success: true,
      data: liveStream
    });

  } catch (error) {
    console.error('Error ending live stream:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to end live stream',
      error: error.message
    });
  }
});

/**
 * Get active live streams
 * GET /api/live/active
 */
router.get('/active', async (req, res) => {
  try {
    const liveStreams = await LiveStream.find({ isLive: true })
      .sort({ viewerCount: -1, startedAt: -1 })
      .limit(50);

    // Generate viewer tokens for each stream
    const streamsWithTokens = await Promise.all(
      liveStreams.map(async (stream) => {
        let token = '';
        if (AGORA_APP_ID && AGORA_APP_CERTIFICATE) {
          const expireTime = 3600; // 1 hour for viewers
          const currentTime = Math.floor(Date.now() / 1000);
          const privilegeExpireTime = currentTime + expireTime;

          token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE,
            stream.agoraChannelName,
            0,
            RtcRole.SUBSCRIBER,
            privilegeExpireTime,
            privilegeExpireTime
          );
        }

        return {
          id: stream._id,
          astrologerId: stream.astrologerId,
          astrologerName: stream.astrologerName,
          astrologerProfilePicture: stream.astrologerProfilePicture,
          astrologerSpecialty: stream.astrologerSpecialty,
          title: stream.title,
          description: stream.description,
          category: stream.category,
          tags: stream.tags,
          viewerCount: stream.viewerCount,
          isLive: stream.isLive,
          startedAt: stream.startedAt,
          likes: stream.likes,
          agoraChannelName: stream.agoraChannelName,
          agoraToken: token
        };
      })
    );

    res.json({
      success: true,
      data: streamsWithTokens
    });

  } catch (error) {
    console.error('Error fetching active streams:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch live streams',
      error: error.message
    });
  }
});

/**
 * Get all live streams (with filters)
 * GET /api/live/streams
 */
router.get('/streams', async (req, res) => {
  try {
    const { category, search } = req.query;
    
    const query = { isLive: true };
    
    if (category) {
      query.category = category;
    }
    
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { astrologerName: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } }
      ];
    }

    const streams = await LiveStream.find(query)
      .sort({ viewerCount: -1, startedAt: -1 });

    res.json({
      success: true,
      data: streams
    });

  } catch (error) {
    console.error('Error fetching streams:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch streams',
      error: error.message
    });
  }
});

/**
 * Get single stream by ID
 * GET /api/live/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const stream = await LiveStream.findById(req.params.id);
    
    if (!stream) {
      return res.status(404).json({
        success: false,
        message: 'Stream not found'
      });
    }

    // Generate viewer token
    let token = '';
    if (AGORA_APP_ID && AGORA_APP_CERTIFICATE && stream.isLive) {
      const expireTime = 3600;
      const currentTime = Math.floor(Date.now() / 1000);
      const privilegeExpireTime = currentTime + expireTime;

      token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        stream.agoraChannelName,
        0,
        RtcRole.SUBSCRIBER,
        privilegeExpireTime,
        privilegeExpireTime
      );
    }

    res.json({
      success: true,
      data: {
        ...stream.toObject(),
        agoraToken: token
      }
    });

  } catch (error) {
    console.error('Error fetching stream:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch stream',
      error: error.message
    });
  }
});

/**
 * Join a stream (increment viewer count)
 * POST /api/live/:streamId/join
 */
router.post('/:streamId/join', async (req, res) => {
  try {
    const { streamId } = req.params;

    const stream = await LiveStream.findByIdAndUpdate(
      streamId,
      { 
        $inc: { viewerCount: 1, totalViews: 1 },
      },
      { new: true }
    );

    if (!stream) {
      return res.status(404).json({
        success: false,
        message: 'Stream not found'
      });
    }

    // Update peak viewer count if needed
    if (stream.viewerCount > stream.peakViewerCount) {
      stream.peakViewerCount = stream.viewerCount;
      await stream.save();
    }

    // Generate token for viewer
    let token = '';
    if (AGORA_APP_ID && AGORA_APP_CERTIFICATE) {
      const expireTime = 3600;
      const currentTime = Math.floor(Date.now() / 1000);
      const privilegeExpireTime = currentTime + expireTime;

      token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        stream.agoraChannelName,
        0,
        RtcRole.SUBSCRIBER,
        privilegeExpireTime,
        privilegeExpireTime
      );
    }

    res.json({
      success: true,
      data: {
        ...stream.toObject(),
        agoraToken: token
      }
    });

  } catch (error) {
    console.error('Error joining stream:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to join stream',
      error: error.message
    });
  }
});

/**
 * Leave a stream (decrement viewer count)
 * POST /api/live/:streamId/leave
 */
router.post('/:streamId/leave', async (req, res) => {
  try {
    const { streamId } = req.params;

    const stream = await LiveStream.findByIdAndUpdate(
      streamId,
      { 
        $inc: { viewerCount: -1 }
      },
      { new: true }
    );

    // Ensure viewer count doesn't go negative
    if (stream && stream.viewerCount < 0) {
      stream.viewerCount = 0;
      await stream.save();
    }

    res.json({
      success: true,
      message: 'Left stream successfully'
    });

  } catch (error) {
    console.error('Error leaving stream:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to leave stream'
    });
  }
});

/**
 * Get viewer count
 * GET /api/live/:streamId/viewers
 */
router.get('/:streamId/viewers', async (req, res) => {
  try {
    const stream = await LiveStream.findById(req.params.streamId).select('viewerCount');
    
    res.json({
      success: true,
      data: {
        count: stream?.viewerCount || 0
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get viewer count'
    });
  }
});

module.exports = router;

