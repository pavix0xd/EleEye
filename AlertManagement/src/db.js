"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var supabase_js_1 = require("@supabase/supabase-js");
var dotenv = require("dotenv");
// Load environment variables from .env file
dotenv.config();
// Check if required environment variables are present
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_KEY) {
    throw new Error("Supabase URL or ANON_KEY is missing from the environment variables.");
}
// Initialize Supabase client using environment variables
var supabase = (0, supabase_js_1.createClient)(process.env.SUPABASE_URL, // Supabase project URL from .env file
process.env.SUPABASE_KEY // Supabase anon key from .env file
);
exports.default = supabase;
