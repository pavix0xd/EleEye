import * as admin from 'firebase-admin';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config();  // Load environment variables from .env file

// Initialize Firebase Admin SDK
const serviceAccount = JSON.parse(process.env.FIREBASE_PRIVATE_KEY as string);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log('Firebase initialized successfully.');
