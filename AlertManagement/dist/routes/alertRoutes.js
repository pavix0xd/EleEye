"use strict";
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
exports.setupAlertRoutes = setupAlertRoutes;
const express = require("express");
const db_1 = __importDefault(require("../db")); // Import the Supabase client
// Define the alertRoutes function to accept `io`
const router = express.Router();
function setupAlertRoutes(io) {
    // Create a new alert
    router.post("/", (req, res) => __awaiter(this, void 0, void 0, function* () {
        const { event_type, location, confidence, source } = req.body;
        try {
            // Insert the new alert into Supabase
            const { data, error } = yield db_1.default
                .from("alerts")
                .insert([{
                    event_type,
                    location,
                    confidence,
                    source
                }])
                .single(); // Get the inserted row
            // Check for Supabase errors
            if (error) {
                console.error("Supabase Error:", error); // Log the Supabase error
                throw error; // Rethrow to be caught in the outer catch block
            }
            // Emit real-time alert (WebSockets)
            io.emit("newAlert", data);
            // Send back the inserted data
            res.json(data);
        }
        catch (err) {
            // General error handling (catching any type of error)
            console.error("Error creating alert:", err instanceof Error ? err.message : err); // Log the detailed error
            res.status(500).json({ error: "An error occurred while creating the alert" });
        }
    }));
    return router;
}
