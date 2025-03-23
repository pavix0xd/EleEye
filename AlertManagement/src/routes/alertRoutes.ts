import express from 'express';
import { Request, Response } from 'express';
import supabase from '../db';  // Import the Supabase client
import { NotificationService } from '../services/notificationService'; // Import the NotificationService

const router = express.Router();

// Interface for the alert object (for better type safety)
interface Alert {
  event_type: string;
  location: string; // Expected to be a string containing both latitude and longitude, e.g. "0.00000 180.00000"
  confidence: number;
  source: string;
}

// Create an instance of the NotificationService
const notificationService = new NotificationService();

// Create a new alert
router.post("/", async (req: Request, res: Response) => {
  const { event_type, location, confidence, source }: Alert = req.body;

  try {
    // Split the location string into latitude and longitude
    const locationParts = location.split(" ");
    if (locationParts.length < 2) {
      throw new Error("Invalid location format. Expected both latitude and longitude.");
    }
    const latitude = parseFloat(locationParts[0]);
    const longitude = parseFloat(locationParts[1]);

    // Insert the new alert into Supabase with latitude and longitude columns
    const { data, error } = await supabase
      .from("alerts")
      .insert([{ 
        event_type,
        latitude,      // New column for latitude
        longitude,     // New column for longitude
        confidence,
        source
      }])
      .single();  // Get the inserted row

    // Check for Supabase errors
    if (error) {
      console.error("Supabase Error:", error);
      throw error;
    }

    // Generate a notification message based on the alert
    const title = `Ele Alert: ${event_type}`;
    const message = `An elephant has been reported in your area with confidence level ${confidence}%. Source: ${source}.`;

    // Send notifications to all users based on the alert's location
    await notificationService.sendPushNotificationToAllUsers(title, message, latitude.toString(), longitude.toString());

    // Send back the inserted data
    res.json(data);

  } catch (err: any) {
    console.error("Error creating alert:", err instanceof Error ? err.message : err);
    res.status(500).json({ error: "An error occurred while creating the alert" });
  }
});

// Export the router as `alertRoutes`
export { router as alertRoutes };