import * as admin from 'firebase-admin';
import * as path from 'path';
import supabase from '../db';  // Ensure supabase client is correctly imported
import * as dotenv from 'dotenv';

dotenv.config();  // Load .env variables

export class NotificationService {
  constructor() {
    try {
      const serviceAccount = path.join(__dirname, '../config/firebase-adminsdk.json');
      
      // Load the service account credentials
      const credentials = require(serviceAccount);

      // Initialize Firebase Admin SDK with credentials
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });

      console.log('Firebase initialized successfully.');
    } catch (error) {
      console.error('Error initializing Firebase:', error);
    }
  }

  // Method to send a push notification to a user using FCM token from Supabase
  async sendPushNotification(userId: string, message: string) {
    try {
      const userToken = await this.getUserFCMToken(userId);  // Fetch FCM token

      if (!userToken) {
        throw new Error('FCM Token not found for user');
      }

      const messagePayload = {
        notification: {
          title: 'New Notification',
          body: message,
        },
        token: userToken,  // Use token to send the message
      };

      const response = await admin.messaging().send(messagePayload);
      console.log('Successfully sent message:', response);
    } catch (error) {
      console.error('Error sending push notification:', error);
      throw error;
    }
  }

  // Method to retrieve FCM token for the user from Supabase
  async getUserFCMToken(userId: string): Promise<string | null> {
    console.log(`Retrieving FCM token for userId: ${userId}`);

    // Fetch token from the Supabase users table (make sure the table has fcm_token column)
    const { data, error } = await supabase
      .from('userInfo')  // Make sure 'userInfo' is your table name (change if needed)
      .select('fcm_token')  // Select the fcm_token column
      .eq('user_id', userId)  // Match the user_id column with the provided userId
      .single();  // Get a single row

    if (error || !data) {
      console.error('Error retrieving FCM token:', error || 'No data found');
      return null;
    }

    console.log('Retrieved FCM token:', data.fcm_token);
    return data.fcm_token;  // Return the token
  }
}
