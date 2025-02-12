import admin from 'firebase-admin';

const privateKey = JSON.parse("${process.env.FIREBASE_PRIVATE_KEY}");

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: privateKey,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});

export class PushService {
  async send(userId: string, message: string) {
    const payload = {
      notification: {
        title: 'Alert Notification',
        body: message,
      },
      token: userId,  // Assuming userId is the device token
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log('Push notification sent:', response);
    } catch (error) {
      console.error('Error sending push notification', error);
      throw error;
    }
  }
}

