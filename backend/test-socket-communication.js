/**
 * Socket.IO Communication Test Script
 * Tests admin-to-astrologer messaging and calling features
 */

const io = require('socket.io-client');
const readline = require('readline');

// Configuration
const BACKEND_URL = 'https://astrologerapp-production.up.railway.app';
const ADMIN_SECRET_KEY = 'admin123';

// Test data - real astrologer ID from your database
const TEST_ASTROLOGER_ID = '6935056d55fcb5a4615f8e8d';
const CONVERSATION_ID = `admin_${TEST_ASTROLOGER_ID}`;

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function separator() {
  log('═'.repeat(60), 'cyan');
}

class SocketTester {
  constructor() {
    this.socket = null;
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
  }

  async connect() {
    return new Promise((resolve, reject) => {
      log('\n🔌 Connecting to Socket.IO server...', 'yellow');
      log(`   URL: ${BACKEND_URL}`, 'blue');
      
      this.socket = io(BACKEND_URL, {
        auth: {
          token: ADMIN_SECRET_KEY,
        },
        transports: ['websocket', 'polling'],
        reconnection: true,
      });

      this.socket.on('connect', () => {
        log('✅ Connected to server!', 'green');
        log(`   Socket ID: ${this.socket.id}`, 'blue');
        resolve();
      });

      this.socket.on('connect_error', (error) => {
        log(`❌ Connection error: ${error.message}`, 'red');
        reject(error);
      });

      this.socket.on('disconnect', (reason) => {
        log(`❌ Disconnected: ${reason}`, 'red');
      });

      // Setup event listeners
      this.setupEventListeners();
    });
  }

  setupEventListeners() {
    // Message events
    this.socket.on('dm:message_received', (message) => {
      log('\n📩 Message received:', 'green');
      console.log(JSON.stringify(message, null, 2));
    });

    this.socket.on('dm:message_sent', (message) => {
      log('\n✅ Message sent successfully:', 'green');
      console.log(JSON.stringify(message, null, 2));
    });

    this.socket.on('dm:history_response', (data) => {
      log('\n📜 Message history:', 'green');
      console.log(`   Conversation: ${data.conversationId}`);
      console.log(`   Messages: ${data.messages.length}`);
      data.messages.forEach((msg, i) => {
        console.log(`   [${i + 1}] ${msg.senderType}: ${msg.content}`);
      });
    });

    // Typing events
    this.socket.on('dm:user_typing', (data) => {
      log(`⌨️  ${data.userType} is typing...`, 'yellow');
    });

    this.socket.on('dm:user_stopped_typing', (data) => {
      log(`⌨️  ${data.userType} stopped typing`, 'yellow');
    });

    // Call events
    this.socket.on('call:incoming', (call) => {
      log('\n📞 Incoming call:', 'green');
      console.log(JSON.stringify(call, null, 2));
    });

    this.socket.on('call:accepted', (call) => {
      log('\n✅ Call accepted:', 'green');
      console.log(JSON.stringify(call, null, 2));
    });

    this.socket.on('call:rejected', (data) => {
      log(`\n❌ Call rejected: ${data.reason || 'No reason'}`, 'red');
    });

    this.socket.on('call:ended', (data) => {
      log('\n📞 Call ended:', 'yellow');
      console.log(`   Duration: ${data.duration || 0}s`);
      console.log(`   Reason: ${data.endReason || 'Normal'}`);
    });

    this.socket.on('call:missed', (data) => {
      log('\n📞 Call missed (timeout)', 'yellow');
      console.log(`   Call ID: ${data.callId}`);
    });

    // Error events
    this.socket.on('error', (error) => {
      log(`\n❌ Error: ${error.message}`, 'red');
    });
  }

  joinConversation() {
    log('\n🚪 Joining conversation...', 'yellow');
    this.socket.emit('dm:join_conversation', {
      conversationId: CONVERSATION_ID,
      userId: 'admin',
      userType: 'admin',
    });
    log(`✅ Joined: ${CONVERSATION_ID}`, 'green');
  }

  sendMessage(content) {
    log('\n📤 Sending message...', 'yellow');
    this.socket.emit('dm:send_message', {
      conversationId: CONVERSATION_ID,
      recipientId: TEST_ASTROLOGER_ID,
      recipientType: 'astrologer',
      content: content,
      messageType: 'text',
    });
  }

  loadHistory() {
    log('\n📜 Loading message history...', 'yellow');
    this.socket.emit('dm:history', {
      conversationId: CONVERSATION_ID,
      page: 1,
      limit: 20,
    });
  }

  startTyping() {
    this.socket.emit('dm:typing_start', {
      conversationId: CONVERSATION_ID,
      userId: 'admin',
      userType: 'admin',
    });
    log('⌨️  Started typing indicator', 'yellow');
  }

  stopTyping() {
    this.socket.emit('dm:typing_stop', {
      conversationId: CONVERSATION_ID,
      userId: 'admin',
      userType: 'admin',
    });
    log('⌨️  Stopped typing indicator', 'yellow');
  }

  initiateCall(callType = 'video') {
    log(`\n📞 Initiating ${callType} call...`, 'yellow');
    this.socket.emit('call:initiate', {
      callerId: 'admin',
      callerType: 'admin',
      recipientId: TEST_ASTROLOGER_ID,
      recipientType: 'astrologer',
      callType: callType,
    });
  }

  async runInteractiveTests() {
    separator();
    log('🧪 SOCKET.IO COMMUNICATION TESTS', 'cyan');
    separator();

    try {
      // Connect
      await this.connect();
      separator();

      // Join conversation
      this.joinConversation();
      await this.wait(1000);

      // Load history
      this.loadHistory();
      await this.wait(2000);

      separator();
      log('\n📋 INTERACTIVE MENU', 'cyan');
      separator();
      this.showMenu();
      this.startInteractiveMode();
    } catch (error) {
      log(`\n❌ Test failed: ${error.message}`, 'red');
      this.cleanup();
    }
  }

  showMenu() {
    console.log(`
  ${colors.cyan}Commands:${colors.reset}
  ${colors.green}1${colors.reset} - Send test message
  ${colors.green}2${colors.reset} - Load message history
  ${colors.green}3${colors.reset} - Start typing indicator
  ${colors.green}4${colors.reset} - Stop typing indicator
  ${colors.green}5${colors.reset} - Initiate voice call
  ${colors.green}6${colors.reset} - Initiate video call
  ${colors.green}m${colors.reset} - Send custom message
  ${colors.green}h${colors.reset} - Show this menu
  ${colors.green}q${colors.reset} - Quit
    `);
  }

  startInteractiveMode() {
    this.rl.setPrompt('> ');
    this.rl.prompt();

    this.rl.on('line', async (input) => {
      const command = input.trim();

      switch (command) {
        case '1':
          this.sendMessage(`Test message from admin at ${new Date().toISOString()}`);
          break;
        case '2':
          this.loadHistory();
          break;
        case '3':
          this.startTyping();
          break;
        case '4':
          this.stopTyping();
          break;
        case '5':
          this.initiateCall('voice');
          break;
        case '6':
          this.initiateCall('video');
          break;
        case 'm':
          this.rl.question('Enter message: ', (msg) => {
            if (msg.trim()) {
              this.sendMessage(msg.trim());
            }
            this.rl.prompt();
          });
          return; // Don't prompt yet
        case 'h':
          this.showMenu();
          break;
        case 'q':
          log('\n👋 Goodbye!', 'yellow');
          this.cleanup();
          return;
        default:
          if (command) {
            log('❌ Invalid command. Type "h" for help.', 'red');
          }
      }

      this.rl.prompt();
    });

    this.rl.on('close', () => {
      this.cleanup();
    });
  }

  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  cleanup() {
    if (this.socket) {
      this.socket.disconnect();
    }
    if (this.rl) {
      this.rl.close();
    }
    process.exit(0);
  }
}

// Run tests
const tester = new SocketTester();
tester.runInteractiveTests().catch((error) => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});

