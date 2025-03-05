const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with the correct path to your service account JSON
admin.initializeApp({
    credential: admin.credential.cert(path.resolve(__dirname, './eleeye-15421-firebase-adminsdk-fbsvc-44983132d7.json')),
});

module.exports = admin; // Export the Firebase Admin module


