// Code for the NotificationService class
import supabase from '../db';  // Ensure supabase client is correctly imported
import * as dotenv from 'dotenv';
import admin from '../config/firebaseConfig';

dotenv.config();  // Load environment variables

export class checkFcmService {

    async checkAndUpdateFcmToken(user_id : string, fcm_token : string){

    }

}