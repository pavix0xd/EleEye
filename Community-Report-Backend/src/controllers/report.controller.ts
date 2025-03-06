import { Request, Response } from "express";
import supabase from "../db/supabase";

// Create a report
export const createReport = async (req: Request, res: Response) : Promise<Response> => {
  try {
    const { latitude, longitude } = req.body;
  
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "Missing required fields" });
    }
  
    const { data, error } = await supabase
      .from("community_reports")
      .insert([{ latitude, longitude }])
      .select(); // Ensure the inserted row is returned
  
    if (error) throw error;
  
    return res.status(201).json({ report: data }); // Ensure it's an array
  } catch (err) {
    console.error("Error creating report:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
 };

// Get all reports
export const getReports = async (req: Request, res: Response)  : Promise<Response> => {
  try {
    const { data, error } = await supabase
      .from("community_reports")
      .select("*");

    if (error) throw error;

    return res.status(200).json({ reports: data });
  } catch (err) {
    console.error("Error retrieving reports:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteReport = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
  
    // Check if the report exists
    const { data: existingReport, error: fetchError } = await supabase
      .from("community_reports")
      .select("id")
      .eq("id", id);
  
    if (fetchError) throw fetchError;
  
    if (!existingReport || existingReport.length === 0) {
      return res.status(404).json({ error: "Report not found" });
    }
  
    // Proceed with deletion
    const { error } = await supabase
      .from("community_reports")
      .delete()
      .eq("id", id);
  
    if (error) throw error;
  
    return res.status(200).json({ message: "Marker deleted successfully" });
  } catch (err) {
    console.error("Error deleting report:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
 };
