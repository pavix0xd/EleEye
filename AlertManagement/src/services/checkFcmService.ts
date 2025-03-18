import supabase from '../db';  // Ensure supabase client is correctly imported
import * as dotenv from 'dotenv';
import admin from '../config/firebaseConfig';

dotenv.config();  // Load environment variables

export class checkFcmService {
    async checkAndUpdateFcmToken(user_id: string, fcm_token: string): Promise<{ success: boolean; message: string }> {
        try {
            // Fetch the current FCM token for the given user ID from the database
            const { data, error } = await supabase
                .from('userInfo') // Replace 'userInfo' with your actual table name
                .select('fcm_token') // Select the fcm_token column
                .eq('id', user_id) // Match the user ID
                .single(); // Ensure only one record is fetched

            if (error) {
                console.error('Error fetching FCM token:', error);
                return { success: false, message: 'Error fetching FCM token from the database.' };
            }

            // Check if the current FCM token matches the given token
            if (data.fcm_token === fcm_token) {
                return { success: true, message: 'FCM token is already up-to-date.' };
            }

            // Update the FCM token in the database
            const { error: updateError } = await supabase
                .from('userInfo') // Replace 'userInfo' with your actual table name
                .update({ fcm_token }) // Update the fcm_token column
                .eq('id', user_id); // Match the user ID

            if (updateError) {
                console.error('Error updating FCM token:', updateError);
                return { success: false, message: 'Error updating FCM token in the database.' };
            }

            return { success: true, message: 'FCM token updated successfully.' };
        } catch (err) {
            console.error('Unexpected error:', err);
            return { success: false, message: 'An unexpected error occurred.' };
        }
    }
}