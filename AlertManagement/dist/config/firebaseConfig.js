"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require('firebase-admin');
const path = require('path');
// Initialize Firebase Admin with the correct path to your service account JSON
admin.initializeApp({
    credential: admin.credential.cert(path.resolve(__dirname, './eleeye-15421-firebase-adminsdk-fbsvc-8b174f87c9.json')),
});
// Export the initialized admin instance
exports.default = admin;
