import express = require('express');
import { Request, Response, Router } from 'express';
// import express , {Request, Response} from 'express';
import { Server } from 'socket.io';
import supabase from '../db';  // Import the Supabase client

// Define the alertRoutes function to accept `io`
const router = express.Router();

// Interface for the alert object (for better type safety)
interface Alert {
  event_type: string;
  location: string;
  confidence: number;
  source: string;
}

export function setupAlertRoutes(io: Server) {
  // Create a new alert
  router.post("/", async (req: Request, res: Response) => {
    const { event_type, location, confidence, source }: Alert = req.body;

    try {
      // Insert the new alert into Supabase
      const { data, error } = await supabase
        .from("alerts")
        .insert([{ 
          event_type,
          location,
          confidence,
          source
        }])
        .single();  // Get the inserted row

      // Check for Supabase errors
      if (error) {
        console.error("Supabase Error:", error);  // Log the Supabase error
        throw error;  // Rethrow to be caught in the outer catch block
      }

      // Emit real-time alert (WebSockets)
      io.emit("newAlert", data);

      // Send back the inserted data
      res.json(data);

    } catch (err: any) {
      // General error handling (catching any type of error)
      console.error("Error creating alert:", err instanceof Error ? err.message : err);  // Log the detailed error
      res.status(500).json({ error: "An error occurred while creating the alert" });
    }
  });

  return router;
}
