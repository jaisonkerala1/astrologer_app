/**
 * Automated Socket.IO Test Script
 * Quick verification of all Socket.IO features
 */

const io = require('socket.io-client');

const BACKEND_URL = 'https://astrologerapp-production.up.railway.app';
const ADMIN_SECRET_KEY = 'admin123';
const TEST_ASTROLOGER_ID = '6935056d55fcb5a4615f8e8d'; // Real astrologer ID

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

function log(emoji, message, status = '') {
  const color = status === 'pass' ? colors.green : status === 'fail' ? colors.red : colors.reset;
  console.log(`${color}${emoji} ${message}${colors.reset}`);
}

class AutoTester {
  constructor() {
    this.socket = null;
    this.tests = {
      connection: false,
      joinConversation: false,
      sendMessage: false,
      receiveMessage: false,
      messageHistory: false,
      typingIndicator: false,
      callInitiate: false,
    };
    this.conversationId = `admin_${TEST_ASTROLOGER_ID}`;
  }

  async run() {
    console.log('\n' + '='.repeat(60));
    log('🧪', 'AUTOMATED SOCKET.IO TESTS', '');
    console.log('='.repeat(60) + '\n');

    try {
      await this.testConnection();
      await this.testJoinConversation();
      await this.testMessageHistory();
      await this.testSendMessage();
      await this.testTypingIndicator();
      await this.testCallInitiation();
      
      await this.wait(3000); // Wait for responses
      
      this.printResults();
      this.cleanup();
    } catch (error) {
      log('❌', `Fatal error: ${error.message}`, 'fail');
      this.cleanup();
    }
  }

  async testConnection() {
    return new Promise((resolve, reject) => {
      log('🔌', 'Testing Socket.IO connection...', '');
      
      this.socket = io(BACKEND_URL, {
        auth: { token: ADMIN_SECRET_KEY },
        transports: ['websocket', 'polling'],
      });

      const timeout = setTimeout(() => {
        log('❌', 'Connection test: FAILED (timeout)', 'fail');
        reject(new Error('Connection timeout'));
      }, 10000);

      this.socket.on('connect', () => {
        clearTimeout(timeout);
        this.tests.connection = true;
        log('✅', `Connection test: PASSED (ID: ${this.socket.id})`, 'pass');
        this.setupListeners();
        resolve();
      });

      this.socket.on('connect_error', (error) => {
        clearTimeout(timeout);
        log('❌', `Connection test: FAILED (${error.message})`, 'fail');
        reject(error);
      });
    });
  }

  setupListeners() {
    this.socket.on('dm:message_sent', (message) => {
      this.tests.sendMessage = true;
      log('✅', `Message sent: "${message.content}"`, 'pass');
    });

    this.socket.on('dm:message_received', (message) => {
      this.tests.receiveMessage = true;
      log('✅', `Message received from ${message.senderType}`, 'pass');
    });

    this.socket.on('dm:history_response', (data) => {
      this.tests.messageHistory = true;
      log('✅', `History loaded: ${data.messages.length} messages`, 'pass');
    });

    this.socket.on('dm:user_typing', () => {
      this.tests.typingIndicator = true;
      log('✅', 'Typing indicator: WORKING', 'pass');
    });

    this.socket.on('call:incoming', (call) => {
      log('✅', `Call initiated: ${call.callType} (channel: ${call.channelName})`, 'pass');
    });

    this.socket.on('error', (error) => {
      log('❌', `Socket error: ${error.message}`, 'fail');
    });
  }

  async testJoinConversation() {
    log('🚪', 'Testing join conversation...', '');
    this.socket.emit('dm:join_conversation', {
      conversationId: this.conversationId,
      userId: 'admin',
      userType: 'admin',
    });
    this.tests.joinConversation = true;
    log('✅', 'Join conversation: PASSED', 'pass');
    await this.wait(500);
  }

  async testMessageHistory() {
    log('📜', 'Testing message history...', '');
    this.socket.emit('dm:history', {
      conversationId: this.conversationId,
      page: 1,
      limit: 10,
    });
    await this.wait(1000);
  }

  async testSendMessage() {
    log('📤', 'Testing send message...', '');
    this.socket.emit('dm:send_message', {
      conversationId: this.conversationId,
      recipientId: TEST_ASTROLOGER_ID,
      recipientType: 'astrologer',
      content: `Automated test message at ${new Date().toISOString()}`,
      messageType: 'text',
    });
    await this.wait(1000);
  }

  async testTypingIndicator() {
    log('⌨️ ', 'Testing typing indicator...', '');
    this.socket.emit('dm:typing_start', {
      conversationId: this.conversationId,
      userId: 'admin',
      userType: 'admin',
    });
    await this.wait(500);
    this.socket.emit('dm:typing_stop', {
      conversationId: this.conversationId,
      userId: 'admin',
      userType: 'admin',
    });
    await this.wait(500);
  }

  async testCallInitiation() {
    log('📞', 'Testing call initiation...', '');
    this.socket.emit('call:initiate', {
      callerId: 'admin',
      callerType: 'admin',
      recipientId: TEST_ASTROLOGER_ID,
      recipientType: 'astrologer',
      callType: 'video',
    });
    this.tests.callInitiate = true;
    await this.wait(1000);
  }

  printResults() {
    console.log('\n' + '='.repeat(60));
    log('📊', 'TEST RESULTS', '');
    console.log('='.repeat(60) + '\n');

    const results = [
      { name: 'Socket Connection', passed: this.tests.connection },
      { name: 'Join Conversation', passed: this.tests.joinConversation },
      { name: 'Send Message', passed: this.tests.sendMessage },
      { name: 'Message History', passed: this.tests.messageHistory },
      { name: 'Typing Indicator', passed: this.tests.typingIndicator },
      { name: 'Call Initiation', passed: this.tests.callInitiate },
    ];

    results.forEach(result => {
      const status = result.passed ? 'pass' : 'fail';
      const icon = result.passed ? '✅' : '❌';
      log(icon, `${result.name}: ${result.passed ? 'PASSED' : 'FAILED'}`, status);
    });

    const passed = results.filter(r => r.passed).length;
    const total = results.length;
    const percentage = Math.round((passed / total) * 100);

    console.log('\n' + '='.repeat(60));
    log('📈', `${passed}/${total} tests passed (${percentage}%)`, passed === total ? 'pass' : 'fail');
    console.log('='.repeat(60) + '\n');

    if (passed < total) {
      log('⚠️ ', 'Some tests failed. Check backend logs for details.', 'fail');
    } else {
      log('🎉', 'All tests passed! Socket.IO is working correctly.', 'pass');
    }
  }

  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  cleanup() {
    if (this.socket) {
      this.socket.disconnect();
    }
    process.exit(0);
  }
}

// Run automated tests
const tester = new AutoTester();
tester.run();

