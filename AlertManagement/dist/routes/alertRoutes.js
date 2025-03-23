"use strict";
// import express from 'express';
// import { Request, Response } from 'express';
// import supabase from '../db';  // Import the Supabase client
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.alertRoutes = void 0;
// const router = express.Router();
// // Interface for the alert object (for better type safety)
// interface Alert {
//   event_type: string;
//   location: string; // Expected to be a string containing both latitude and longitude, e.g. "0.00000 180.00000"
//   confidence: number;
//   source: string;
// }
// // Create a new alert
// router.post("/", async (req: Request, res: Response) => {
//   const { event_type, location, confidence, source }: Alert = req.body;
//   try {
//     // Split the location string into latitude and longitude
//     const locationParts = location.split(" ");
//     if (locationParts.length < 2) {
//       throw new Error("Invalid location format. Expected both latitude and longitude.");
//     }
//     const latitude = parseFloat(locationParts[0]);
//     const longitude = parseFloat(locationParts[1]);
//     // Insert the new alert into Supabase with latitude and longitude columns
//     const { data, error } = await supabase
//       .from("alerts")
//       .insert([{ 
//         event_type,
//         latitude,      // New column for latitude
//         longitude,     // New column for longitude
//         confidence,
//         source
//       }])
//       .single();  // Get the inserted row
//     // Check for Supabase errors
//     if (error) {
//       console.error("Supabase Error:", error);
//       throw error;
//     }
//     // Send back the inserted data
//     res.json(data);
//   } catch (err: any) {
//     console.error("Error creating alert:", err instanceof Error ? err.message : err);
//     res.status(500).json({ error: "An error occurred while creating the alert" });
//   }
// });
// // Export the router as `alertRoutes`
// export { router as alertRoutes };
const express_1 = __importDefault(require("express"));
const db_1 = __importDefault(require("../db")); // Import the Supabase client
const notificationService_1 = require("../services/notificationService"); // Import the NotificationService
const router = express_1.default.Router();
exports.alertRoutes = router;
// Create an instance of the NotificationService
const notificationService = new notificationService_1.NotificationService();
// Create a new alert
router.post("/", (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { event_type, location, confidence, source } = req.body;
    try {
        // Split the location string into latitude and longitude
        const locationParts = location.split(" ");
        if (locationParts.length < 2) {
            throw new Error("Invalid location format. Expected both latitude and longitude.");
        }
        const latitude = parseFloat(locationParts[0]);
        const longitude = parseFloat(locationParts[1]);
        // Insert the new alert into Supabase with latitude and longitude columns
        const { data, error } = yield db_1.default
            .from("alerts")
            .insert([{
                event_type,
                latitude, // New column for latitude
                longitude, // New column for longitude
                confidence,
                source
            }])
            .single(); // Get the inserted row
        // Check for Supabase errors
        if (error) {
            console.error("Supabase Error:", error);
            throw error;
        }
        // Generate a notification message based on the alert
        const title = `Object Detection Alert: ${event_type}`;
        const message = `An object detection alert has been reported in your area with confidence level ${confidence}%. Source: ${source}.`;
        // Send notifications to all users based on the alert's location
        yield notificationService.sendPushNotificationToAllUsers(title, message, latitude.toString(), longitude.toString());
        // Send back the inserted data
        res.json(data);
    }
    catch (err) {
        console.error("Error creating alert:", err instanceof Error ? err.message : err);
        res.status(500).json({ error: "An error occurred while creating the alert" });
    }
}));
