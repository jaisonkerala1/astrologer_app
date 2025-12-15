/**
 * Discussion Socket Handler
 * Handles real-time events for discussions (comments, likes, replies)
 */

const EVENTS = require('../events');
const Discussion = require('../../models/Discussion');
const DiscussionComment = require('../../models/DiscussionComment');
const Astrologer = require('../../models/Astrologer');

/**
 * Calculate time ago string from date
 */
function getTimeAgo(date) {
  const now = new Date();
  const diff = now - new Date(date);
  
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (seconds < 60) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  return `${days}d ago`;
}

/**
 * Initialize discussion socket handlers
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 * @param {Object} roomManager - Room manager for tracking users in rooms
 */
function initDiscussionHandler(socket, io, roomManager) {
  const user = socket.user;

  if (!user) {
    console.log('⚠️ [DISCUSSION] No user attached to socket');
    return;
  }

  /**
   * Join a discussion room to receive real-time updates
   * Event: discussion:join
   * Payload: { discussionId }
   */
  socket.on(EVENTS.DISCUSSION.JOIN, async (data) => {
    try {
      const { discussionId } = data;

      if (!discussionId) {
        socket.emit(EVENTS.ERROR, { message: 'Discussion ID is required' });
        return;
      }

      // Verify discussion exists
      const discussion = await Discussion.findById(discussionId);
      if (!discussion || !discussion.isActive) {
        socket.emit(EVENTS.ERROR, { message: 'Discussion not found' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.DISCUSSION}${discussionId}`;

      // Leave any other discussion rooms first
      socket.rooms.forEach((room) => {
        if (room.startsWith(EVENTS.ROOM_PREFIX.DISCUSSION) && room !== roomId) {
          socket.leave(room);
          console.log(`📤 [DISCUSSION] ${user.name} left room ${room}`);
        }
      });

      // Join the discussion room
      socket.join(roomId);
      roomManager.joinRoom(socket.id, roomId, user);

      console.log(`📥 [DISCUSSION] ${user.name} joined discussion: ${discussion.title}`);

      // Acknowledge successful join
      socket.emit('discussion:joined', {
        discussionId,
        title: discussion.title,
        message: 'Joined discussion room'
      });

    } catch (error) {
      console.error('❌ [DISCUSSION] Join error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to join discussion' });
    }
  });

  /**
   * Leave a discussion room
   * Event: discussion:leave
   * Payload: { discussionId }
   */
  socket.on(EVENTS.DISCUSSION.LEAVE, async (data) => {
    try {
      const { discussionId } = data;

      if (!discussionId) {
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.DISCUSSION}${discussionId}`;
      socket.leave(roomId);
      roomManager.leaveRoom(socket.id, roomId);

      console.log(`📤 [DISCUSSION] ${user.name} left discussion: ${discussionId}`);

      socket.emit('discussion:left', {
        discussionId,
        message: 'Left discussion room'
      });

    } catch (error) {
      console.error('❌ [DISCUSSION] Leave error:', error);
    }
  });

  /**
   * Send a comment (handled via API, but socket can also be used)
   * Event: discussion:comment
   * Payload: { discussionId, content, parentCommentId? }
   */
  socket.on(EVENTS.DISCUSSION.COMMENT, async (data) => {
    try {
      const { discussionId, content, parentCommentId } = data;

      if (!discussionId || !content || !content.trim()) {
        socket.emit(EVENTS.ERROR, { message: 'Discussion ID and content are required' });
        return;
      }

      // Verify discussion exists
      const discussion = await Discussion.findById(discussionId);
      if (!discussion || !discussion.isActive) {
        socket.emit(EVENTS.ERROR, { message: 'Discussion not found' });
        return;
      }

      // Get author info
      const author = await Astrologer.findById(user.id);
      if (!author) {
        socket.emit(EVENTS.ERROR, { message: 'Author not found' });
        return;
      }

      // If replying, verify parent exists
      if (parentCommentId) {
        const parentComment = await DiscussionComment.findById(parentCommentId);
        if (!parentComment) {
          socket.emit(EVENTS.ERROR, { message: 'Parent comment not found' });
          return;
        }
        await parentComment.incrementReplyCount();
      }

      // Create comment
      const comment = new DiscussionComment({
        discussionId: discussion._id,
        parentCommentId: parentCommentId || null,
        authorId: author._id,
        authorName: author.name,
        authorAvatar: author.profilePicture,
        content: content.trim()
      });

      await comment.save();
      await discussion.incrementCommentCount();

      const commentData = {
        id: comment._id.toString(),
        discussionId: discussion._id.toString(),
        parentCommentId: comment.parentCommentId?.toString() || null,
        author: comment.authorName,
        authorId: comment.authorId.toString(),
        authorInitial: comment.authorName.charAt(0).toUpperCase(),
        authorAvatar: comment.authorAvatar,
        content: comment.content,
        likes: 0,
        isLiked: false,
        repliesCount: 0,
        createdAt: comment.createdAt,
        timeAgo: 'Just now'
      };

      const roomId = `${EVENTS.ROOM_PREFIX.DISCUSSION}${discussionId}`;

      // Broadcast to all users in the discussion room
      if (parentCommentId) {
        io.to(roomId).emit(EVENTS.DISCUSSION.REPLY, commentData);
      } else {
        io.to(roomId).emit(EVENTS.DISCUSSION.COMMENT, commentData);
      }

      // Update discussion list for everyone (comment count changed)
      io.emit(EVENTS.DISCUSSION.UPDATE, {
        type: 'comment_added',
        discussionId: discussion._id.toString(),
        commentsCount: discussion.commentsCount
      });

      console.log(`💬 [DISCUSSION] ${parentCommentId ? 'Reply' : 'Comment'} from ${author.name}`);

    } catch (error) {
      console.error('❌ [DISCUSSION] Comment error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to post comment' });
    }
  });

  /**
   * Toggle like on discussion or comment (via socket for real-time)
   * Event: discussion:like
   * Payload: { discussionId, commentId? }
   */
  socket.on(EVENTS.DISCUSSION.LIKE, async (data) => {
    try {
      const { discussionId, commentId } = data;

      if (!discussionId && !commentId) {
        socket.emit(EVENTS.ERROR, { message: 'Discussion ID or Comment ID is required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.DISCUSSION}${discussionId}`;

      if (commentId) {
        // Like on comment
        const comment = await DiscussionComment.findById(commentId);
        if (!comment) {
          socket.emit(EVENTS.ERROR, { message: 'Comment not found' });
          return;
        }

        const isNowLiked = await comment.toggleLike(user.id);

        io.to(roomId).emit(EVENTS.DISCUSSION.LIKE, {
          type: 'comment',
          commentId: comment._id.toString(),
          discussionId: comment.discussionId.toString(),
          likesCount: comment.likesCount,
          userId: user.id,
          isLiked: isNowLiked
        });

        console.log(`${isNowLiked ? '❤️' : '💔'} [DISCUSSION] Comment like by ${user.name}`);

      } else {
        // Like on discussion
        const discussion = await Discussion.findById(discussionId);
        if (!discussion) {
          socket.emit(EVENTS.ERROR, { message: 'Discussion not found' });
          return;
        }

        const isNowLiked = await discussion.toggleLike(user.id);

        io.to(roomId).emit(EVENTS.DISCUSSION.LIKE, {
          type: 'discussion',
          discussionId: discussion._id.toString(),
          likesCount: discussion.likesCount,
          userId: user.id,
          isLiked: isNowLiked
        });

        console.log(`${isNowLiked ? '❤️' : '💔'} [DISCUSSION] Post like by ${user.name}`);
      }

    } catch (error) {
      console.error('❌ [DISCUSSION] Like error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to toggle like' });
    }
  });

  /**
   * Handle disconnect - cleanup discussion rooms
   */
  socket.on('disconnect', () => {
    // Clean up all discussion rooms for this socket
    socket.rooms.forEach((room) => {
      if (room.startsWith(EVENTS.ROOM_PREFIX.DISCUSSION)) {
        roomManager.leaveRoom(socket.id, room);
      }
    });
  });
}

module.exports = { initDiscussionHandler };

