import admin from 'firebase-admin';

// Initialize Firebase Admin SDK with your service account
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});

export class PushService {
  /**
   * Sends a push notification to a specific user
   * @param userId The FCM device token of the user
   * @param message The message to be sent in the notification
   */
  async send(userId: string, message: string) {
    const payload = {
      notification: {
        title: 'Alert Notification',  // Title of the notification
        body: message,               // Message to display in the notification
      },
      token: userId,  // This should be the FCM token of the user’s device
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
