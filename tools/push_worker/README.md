Tenzin Push Worker
===================

This small Node.js worker reads FCM tokens stored in the Appwrite `push_tokens` collection and sends push notifications via Firebase Admin.

Setup
-----

1. Create a `.env` file in this folder with:

```
APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=69536e3f003c0ac930bd
APPWRITE_API_KEY=your_server_key_here
APPWRITE_DATABASE_ID=your_database_id
APPWRITE_COLLECTION_ID=push_tokens

FIREBASE_SERVICE_ACCOUNT_JSON=./serviceAccount.json

# Optional
PUSH_TITLE="Tenzin"
PUSH_BODY="Hello from Tenzin"
PUSH_DATA={}
```

2. Place your Firebase service account JSON at the path referenced by `FIREBASE_SERVICE_ACCOUNT_JSON` (or change the env var to point to the file).

3. Install dependencies and run:

```bash
cd tools/push_worker
npm install
npm start
```

Behavior
--------
- Reads up to 500 documents at a time from the `push_tokens` collection.
- Sends multicast messages via Firebase Admin (up to 500 tokens per call).
- Marks documents with `sent: true`, `sent_at`, and `last_result` after sending.

Notes
-----
- Ensure the Appwrite API key has permission to read/list/update documents in the specified collection.
- This worker is intentionally simple — extend with batching, retries, backoff, and error handling as needed.
