const admin = require('firebase-admin');

let messaging = null;

const cleanEnvValue = (value) => {
  if (value === undefined || value === null) return '';
  let v = String(value).trim();

  // Strip wrapping quotes that some dashboards may add
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
    v = v.slice(1, -1);
  }

  return v.trim();
};

const normalizePrivateKey = (rawValue) => {
  let v = cleanEnvValue(rawValue);

  // Handle escaped newlines (\n / \r\n) and real newlines (\r\n)
  v = v.replace(/\\r\\n/g, '\n');
  v = v.replace(/\\n/g, '\n');
  v = v.replace(/\r\n/g, '\n');

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
  const fs = require('fs');
  const path = require('path');
  const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

  if (admin.apps && admin.apps.length > 0) {
    console.log('[FCM] Firebase Admin already initialized');
  } else if (fs.existsSync(serviceAccountPath)) {
    // Local development only: file should NOT be committed
    // eslint-disable-next-line global-require
    const serviceAccount = require('../../firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('[FCM] Firebase Admin initialized with service account file');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    // Production (recommended): base64 encoded service account JSON
    const jsonStr = Buffer.from(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64), 'base64').toString('utf8');
    const serviceAccount = JSON.parse(jsonStr);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('[FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_BASE64');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    // Alternative: raw JSON string
    const serviceAccount = JSON.parse(cleanEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_JSON));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('[FCM] Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT_JSON');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    // Legacy env var setup
    const privateKey = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: cleanEnvValue(process.env.FIREBASE_PROJECT_ID),
        privateKey,
        clientEmail: cleanEnvValue(process.env.FIREBASE_CLIENT_EMAIL),
      }),
    });

    console.log('[FCM] Firebase Admin initialized with environment variables');
  } else {
    console.warn('[FCM] Firebase credentials not found. FCM notifications will be disabled.');
    console.warn('[FCM] Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL');
    console.warn('[FCM] Or set FIREBASE_SERVICE_ACCOUNT_BASE64 (recommended) / FIREBASE_SERVICE_ACCOUNT_JSON');
  }

  messaging = admin.messaging();
} catch (error) {
  console.error('[FCM] Failed to initialize Firebase Admin:', error.message);

  // Safe diagnostics (no secrets printed)
  try {
    if (process.env.FIREBASE_PRIVATE_KEY) {
      const pk = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
      console.error('[FCM] FIREBASE_PRIVATE_KEY diagnostics:', privateKeyDiagnostics(pk));
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      console.error('[FCM] FIREBASE_SERVICE_ACCOUNT_BASE64 present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64).length);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      console.error('[FCM] FIREBASE_SERVICE_ACCOUNT_JSON present (length):', String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON).length);
    } else {
      console.error('[FCM] No firebase env vars detected');
    }
  } catch (_) {
    // ignore diagnostics failures
  }

  console.warn('[FCM] Push notifications will be disabled');
}

module.exports = { messaging, admin };
