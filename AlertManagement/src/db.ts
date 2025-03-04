import { createClient } from "@supabase/supabase-js";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Check if required environment variables are present
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  throw new Error("Supabase URL or ANON_KEY is missing from the environment variables.");
}

// Initialize Supabase client using environment variables
const supabase = createClient(
  process.env.SUPABASE_URL,   // Supabase project URL from .env file
  process.env.SUPABASE_ANON_KEY // Supabase anon key from .env file
);

export default supabase;