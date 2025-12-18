const admin = require('firebase-admin');

let messaging = null;

try {
  // Check if running locally with service account file
  const fs = require('fs');
  const path = require('path');
  const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
  
  if (fs.existsSync(serviceAccountPath)) {
    // Local development: Use service account JSON file
    const serviceAccount = require('../../firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with service account file');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    // Production: Use environment variables
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
    console.log('✅ [FCM] Firebase Admin initialized with environment variables');
  } else {
    console.warn('⚠️ [FCM] Firebase credentials not found. FCM notifications will be disabled.');
    console.warn('⚠️ [FCM] Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in environment');
  }
  
  messaging = admin.messaging();
} catch (error) {
  console.error('❌ [FCM] Failed to initialize Firebase Admin:', error.message);
  console.warn('⚠️ [FCM] Push notifications will be disabled');
}

module.exports = { messaging, admin };

