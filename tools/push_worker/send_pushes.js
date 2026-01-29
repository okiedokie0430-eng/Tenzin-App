require('dotenv').config();
const sdk = require('node-appwrite');
const admin = require('firebase-admin');
const fs = require('fs');

const APPWRITE_ENDPOINT = process.env.APPWRITE_ENDPOINT;
const APPWRITE_PROJECT = process.env.APPWRITE_PROJECT_ID;
const APPWRITE_KEY = process.env.APPWRITE_API_KEY;
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'default';
const COLLECTION_ID = process.env.APPWRITE_COLLECTION_ID || 'push_tokens';
const FIREBASE_SERVICE_ACCOUNT_JSON = process.env.FIREBASE_SERVICE_ACCOUNT_JSON; // path to JSON file

if (!APPWRITE_ENDPOINT || !APPWRITE_PROJECT || !APPWRITE_KEY) {
  console.error('Missing Appwrite configuration in .env');
  process.exit(1);
}

if (!FIREBASE_SERVICE_ACCOUNT_JSON) {
  console.error('Missing FIREBASE_SERVICE_ACCOUNT_JSON env var (path to service account JSON)');
  process.exit(1);
}

// Initialize Appwrite client
const client = new sdk.Client()
  .setEndpoint(APPWRITE_ENDPOINT)
  .setProject(APPWRITE_PROJECT)
  .setKey(APPWRITE_KEY);

const databases = new sdk.Databases(client);

// Initialize Firebase Admin
const serviceAccount = JSON.parse(fs.readFileSync(FIREBASE_SERVICE_ACCOUNT_JSON, 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function fetchTokens(limit = 100) {
  try {
    const resp = await databases.listDocuments(DATABASE_ID, COLLECTION_ID, [sdk.Query.limit(limit)]);
    return resp.documents || [];
  } catch (e) {
    console.error('Error fetching tokens:', e);
    return [];
  }
}

async function sendBatch(tokens, payload) {
  if (!tokens.length) return { success: 0, failure: 0 };

  const registrationTokens = tokens.map(t => t.token).filter(Boolean);
  if (!registrationTokens.length) return { success: 0, failure: 0 };

  const message = {
    tokens: registrationTokens,
    notification: payload.notification,
    data: payload.data || {},
  };

  try {
    const res = await admin.messaging().sendMulticast(message);
    return { success: res.successCount, failure: res.failureCount, responses: res.responses };
  } catch (e) {
    console.error('Error sending multicast:', e);
    return { success: 0, failure: registrationTokens.length };
  }
}

async function markSent(documentId, result) {
  try {
    await databases.updateDocument(DATABASE_ID, COLLECTION_ID, documentId, {
      sent: true,
      sent_at: Date.now(),
      last_result: JSON.stringify(result),
    });
  } catch (e) {
    console.error('Failed to mark token sent for', documentId, e);
  }
}

async function run() {
  console.log('Fetching tokens from Appwrite...');
  const tokens = await fetchTokens(500);
  console.log(`Found ${tokens.length} token documents.`);

  // chunk tokens by 500 (Firebase limit)
  const chunkSize = 500;
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const payload = {
      notification: {
        title: process.env.PUSH_TITLE || 'Tenzin',
        body: process.env.PUSH_BODY || 'Hello from Tenzin!'
      },
      data: process.env.PUSH_DATA ? JSON.parse(process.env.PUSH_DATA) : {}
    };

    console.log(`Sending chunk ${i/chunkSize + 1} (${chunk.length} tokens)`);
    const result = await sendBatch(chunk, payload);
    console.log('Result:', result);

    // mark each document as sent
    for (const doc of chunk) {
      await markSent(doc.$id, result);
    }
  }

  console.log('Done.');
}

run().catch(e => console.error(e));
