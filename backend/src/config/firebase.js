const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let messaging = null;

const cleanEnvValue = (value) => {
  if (value === undefined || value === null) return '';
  let v = String(value).trim();
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
    v = v.slice(1, -1);
  }
  return v.trim();
};

const normalizePrivateKey = (rawValue) => {
  let v = cleanEnvValue(rawValue);
  v = v.replace(/\\r\\n/g, '\n').replace(/\\n/g, '\n').replace(/\r\n/g, '\n');
  return v.trim();
};

const privateKeyDiagnostics = (pk) => {
  const v = String(pk || '');
  const newlineCount = (v.match(/\n/g) || []).length;
  return {
    present: Boolean(pk),
    length: v.length,
    newlineCount,
    containsEscapedNewlines: v.includes('\\n'),
    startsWithBegin: v.startsWith('-----BEGIN PRIVATE KEY-----'),
    endsWithEnd:
      v.endsWith('-----END PRIVATE KEY-----') ||
      v.endsWith('-----END PRIVATE KEY-----\n') ||
      v.endsWith('-----END PRIVATE KEY-----\r\n'),
    containsDoubleQuotes: v.includes('"'),
    containsSingleQuotes: v.includes("'"),
  };
};

try {
  const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

  if (admin.apps && admin.apps.length > 0) {
    console.log('ℹ️ [FCM] Firebase Admin already initialized');
  } else if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require('../../firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with service account file');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    const jsonStr = Buffer.from(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64), 'base64').toString('utf8');
    const serviceAccount = JSON.parse(jsonStr);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_BASE64');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_JSON));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_JSON');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    const privateKey = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: cleanEnvValue(process.env.FIREBASE_PROJECT_ID),
        privateKey,
        clientEmail: cleanEnvValue(process.env.FIREBASE_CLIENT_EMAIL),
      }),
    });
    console.log('✅ [FCM] Firebase Admin initialized with environment variables');
  } else {
    console.warn('⚠️ [FCM] Firebase credentials not found. FCM notifications will be disabled.');
    console.warn('⚠️ [FCM] Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in environment');
    console.warn('⚠️ [FCM] Or set FIREBASE_SERVICE_ACCOUNT_BASE64 (recommended) / FIREBASE_SERVICE_ACCOUNT_JSON');
  }

  messaging = admin.messaging();
} catch (error) {
  console.error('❌ [FCM] Failed to initialize Firebase Admin:', error.message);
  try {
    if (process.env.FIREBASE_PRIVATE_KEY) {
      const pk = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
      console.error('🧪 [FCM] FIREBASE_PRIVATE_KEY diagnostics:', privateKeyDiagnostics(pk));
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      console.error('🧪 [FCM] FIREBASE_SERVICE_ACCOUNT_BASE64 present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64).length);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      console.error('🧪 [FCM] FIREBASE_SERVICE_ACCOUNT_JSON present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON).length);
    } else {
      console.error('🧪 [FCM] No firebase env vars detected');
    }
  } catch (_) {
    // ignore secondary diagnostic failures
  }
  console.warn('⚠️ [FCM] Push notifications will be disabled');
}

module.exports = { messaging, admin };







    };
  };

  // Check if running locally with service account file
  const fs = require('fs');
  const path = require('path');
  const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
  
  if (admin.apps && admin.apps.length > 0) {
    // Already initialized elsewhere (avoid duplicate init crashes in dev/hot-reload)
    console.log('ℹ️ [FCM] Firebase Admin already initialized');
  } else if (fs.existsSync(serviceAccountPath)) {
    // Local development: Use service account JSON file
    const serviceAccount = require('../../firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with service account file');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    // Production (recommended): Use base64 encoded service-account JSON to avoid newline/env UI issues
    const jsonStr = Buffer.from(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64), 'base64').toString('utf8');
    const serviceAccount = JSON.parse(jsonStr);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_BASE64');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    // Alternative: Raw JSON string in env var
    const serviceAccount = JSON.parse(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_JSON));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ [FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_JSON');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    // Production: Use environment variables
    const privateKey = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: cleanEnvValue(process.env.FIREBASE_PROJECT_ID),
        privateKey,
        clientEmail: cleanEnvValue(process.env.FIREBASE_CLIENT_EMAIL),
      }),
    });
    console.log('✅ [FCM] Firebase Admin initialized with environment variables');
  } else {
    console.warn('⚠️ [FCM] Firebase credentials not found. FCM notifications will be disabled.');
    console.warn('⚠️ [FCM] Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in environment');
    console.warn('⚠️ [FCM] Or set FIREBASE_SERVICE_ACCOUNT_BASE64 (recommended) / FIREBASE_SERVICE_ACCOUNT_JSON');
  }
  
  messaging = admin.messaging();
} catch (error) {
  console.error('❌ [FCM] Failed to initialize Firebase Admin:', error.message);
  // Help debug env formatting without printing secrets
  try {
    if (process.env.FIREBASE_PRIVATE_KEY) {
      const pk = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
      console.error('🧪 [FCM] FIREBASE_PRIVATE_KEY diagnostics:', privateKeyDiagnostics(pk));
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      console.error('🧪 [FCM] FIREBASE_SERVICE_ACCOUNT_BASE64 present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64).length);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      console.error('🧪 [FCM] FIREBASE_SERVICE_ACCOUNT_JSON present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON).length);
    } else {
      console.error('🧪 [FCM] No firebase env vars detected');
    }
  } catch (_) {
    // ignore secondary diagnostic failures
  }
  console.warn('⚠️ [FCM] Push notifications will be disabled');
}

module.exports = { messaging, admin };




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



