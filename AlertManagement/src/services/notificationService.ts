// src/services/notificationService.ts
import * as admin from 'firebase-admin';
import * as path from 'path';
import supabase from '../db';  // Import the supabase client from db.ts

export class NotificationService {
  constructor() {
    const serviceAccount = path.join(__dirname, '../config/firebase-adminsdk.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('Firebase initialized successfully.');
  }

  // Function to send a push notification
  async sendPushNotification(userId: string, message: string) {
    try {
      const userToken = await this.getUserFCMToken(userId);  // Retrieve FCM token

      if (!userToken) {
        throw new Error('FCM Token not found for user');
      }

      const messagePayload = {
        notification: {
          title: 'New Notification',
          body: message,
        },
        token: userToken,  // Use the token from Supabase
      };

      // Send the push notification using Firebase Admin SDK
      const response = await admin.messaging().send(messagePayload);
      console.log('Successfully sent message:', response);
    } catch (error) {
      console.error('Error sending push notification:', error);
      throw error;
    }
  }

  // Function to retrieve the FCM token for the user from Supabase
  async getUserFCMToken(userId: string): Promise<string | null> {
    console.log(`Retrieving FCM token for userId: ${userId}`);

    // Fetch the token from Supabase (make sure 'users' is your actual table name)
    const { data, error } = await supabase
      .from('users')  // Make sure 'users' is your table name
      .select('fcm_token')  // Select the 'fcm_token' column
      .eq('user_id', userId)  // Match the user_id column with the provided userId
      .single();  // Fetch only a single row

    if (error || !data) {
      console.error('Error retrieving FCM token:', error);
      return null;
    }

    return data.fcm_token;  // Return the FCM token
  }
}
