const http = require('http');

// Test the server
const testServer = () => {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/health',
    method: 'GET'
  };

  const req = http.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers: ${JSON.stringify(res.headers)}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Response:', data);
    });
  });

  req.on('error', (error) => {
    console.error('Error:', error.message);
  });

  req.end();
};

// Test send OTP
const testSendOTP = () => {
  const postData = JSON.stringify({
    phone: '+1234567890'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/send-otp',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const req = http.request(options, (res) => {
    console.log(`Send OTP Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Send OTP Response:', data);
    });
  });

  req.on('error', (error) => {
    console.error('Send OTP Error:', error.message);
  });

  req.write(postData);
  req.end();
};

// Wait a bit for server to start, then test
setTimeout(() => {
  console.log('Testing server...');
  testServer();
  
  setTimeout(() => {
    console.log('Testing send OTP...');
    testSendOTP();
  }, 1000);
}, 2000);




