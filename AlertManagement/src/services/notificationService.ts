
import supabase from '../db';  // Ensure supabase client is correctly imported
import * as dotenv from 'dotenv';
import admin from '../config/firebaseConfig';

dotenv.config();  // Load environment variables

export class NotificationService {
  constructor() {
    try {
      // Firebase Admin initialization is handled in firebaseConfig.ts, no need for re-initialization here
      console.log('Firebase initialized successfully.');
    } catch (error) {
      console.error('Error initializing Firebase:', error);
    }
  }

  // Method to send a push notification to all users
  async sendPushNotificationToAllUsers(title: string, message: string,latitude: string,longitude: string) {
    try {
      // Fetch all FCM tokens and userIds from Supabase
      const userTokens = await this.getAllUserFCMTokens();  // Fetch all FCM tokens with userId
      const fetchCity = await this.getCity(latitude,longitude);
      console.log(fetchCity);

      if (!userTokens || userTokens.length === 0) {
        throw new Error('No FCM tokens found for users');
      }

     // Prepare the combined city name in the required format
    const cityName = `${fetchCity.name_en} ${fetchCity.name_si} ${fetchCity.name_ta}`;


      const message_content = ` ${message} in ${cityName}`; // Combine message with city name

      // Loop through all tokens and send notifications
      const promises = userTokens.map(async ({ userId, fcm_token }) => {
        const messagePayload = {
          notification: {
            title: title, // Use title passed from frontend
            body:message_content, // Use message passed from frontend
            
          },
          token: fcm_token, // Explicitly include the token property here
        };

        const response = await admin.messaging().send(messagePayload); // Send message
        console.log('Successfully sent message:', response);
        
        // Call the method to save the notification in the database per user
        await this.saveNotification(userId, title, message_content); // Save notification per user
        return response; // Return response for further use
      });

      // Wait for all notifications to be sent
      const responses = await Promise.all(promises);
      return { success: true, responses };
    } catch (error) {
      console.error('Error sending push notifications to all users:', error);
      throw error;
    }
  }

  // Method to retrieve all FCM tokens and userIds for users from Supabase
  async getAllUserFCMTokens(): Promise<{ userId: string, fcm_token: string }[]> {
    console.log('Retrieving all FCM tokens for users.');

    try {
      // Fetch all tokens and userIds from the Supabase users table
      const { data, error } = await supabase
        .from('userInfo')  // Make sure 'userInfo' is your table name
        .select('id, fcm_token');  // Select the userId and fcm_token columns

      if (error) {
        throw new Error(`Error retrieving FCM tokens: ${error.message}`);
      }

      if (!data || data.length === 0) {
        throw new Error('No FCM tokens found in the database');
      }

      // Map and return an array of objects containing userId and fcm_token
      const tokens = data.map((user: { id: string, fcm_token: string }) => ({
        userId: user.id,
        fcm_token: user.fcm_token
      }));

      console.log('Retrieved FCM tokens:', tokens);
      return tokens;
    } catch (err) {
      console.error('Error in getAllUserFCMTokens:', err);
      return [];  // Return an empty array in case of an error
    }
  }

  // Method to save the notification to the database for each user
  async saveNotification(receiverId: string, notificationTitle: string, notificationMessage: string): Promise<void> {
    console.log(`Saving notification for receiverId: ${receiverId}`);

    try {
      // Insert the notification into the notifications table for each user
      const { data, error } = await supabase
        .from('notifications')  // Make sure 'notifications' is your table name
        .insert([
          {
            receiver_id: receiverId,  // Store the receiver_id for each notification
            notification_title: notificationTitle,
            notification_message: notificationMessage,
          },
        ]);

      if (error) {
        throw new Error(`Error saving notification for user ${receiverId}: ${error.message}`);
      }

      console.log('Notification saved successfully:', data);
    } catch (err) {
      console.error('Error in saveNotification:', err);
      throw err;  // Re-throw the error to handle it in the calling method
    }
  }


  async getCity(latitude: string, longitude: string) {
    try {
      // Convert latitude and longitude to radians
      const lat1 = parseFloat(latitude) * (Math.PI / 180);
      const lon1 = parseFloat(longitude) * (Math.PI / 180);
  
      // Fetch all cities with their latitudes and longitudes
      const { data, error } = await supabase
        .from('cities')  // Ensure 'cities' is the table name
        .select('id, name_en, name_si, name_ta, latitude, longitude');
  
      if (error) {
        throw new Error(`Error fetching city data: ${error.message}`);
      }
  
      if (!data || data.length === 0) {
        throw new Error('No cities found in the database');
      }
  
      // Find the nearest city by calculating the distance using the Haversine formula
      let nearestCity = null;
      let minDistance = Infinity;
  
      for (const city of data) {
        // Convert city latitude and longitude to radians
        const lat2 = parseFloat(city.latitude) * (Math.PI / 180);
        const lon2 = parseFloat(city.longitude) * (Math.PI / 180);
  
        // Haversine formula to calculate the distance
        const deltaLat = lat2 - lat1;
        const deltaLon = lon2 - lon1;
        const a = Math.sin(deltaLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) ** 2;
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const distance = 6371 * c; // Distance in kilometers
  
        // If this city is closer, update the nearest city
        if (distance < minDistance) {
          minDistance = distance;
          nearestCity = city;
        }
      }
  
      if (!nearestCity) {
        throw new Error('No nearest city found');
      }
  
      // Return the nearest city data (name_en, name_si, name_ta)
      return nearestCity;
    } catch (err) {
      console.error('Error in getCity:', err);
      throw err;  // Rethrow the error
    }
  }
}
