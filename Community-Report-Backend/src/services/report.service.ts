import supabase from "../db/supabase";
import { Report } from "../models/report.model";

// Function to create a new report
export const createReport = async (report: Report): Promise<Report | null> => {
  const { data, error } = await supabase
    .from("community_reports")
    .insert([
      {
        latitude: report.latitude,
        longitude: report.longitude,
      },
    ])
    .select("*") // This ensures that we return the inserted data
    .single(); // Ensures we return a single object instead of an array

  if (error) {
    console.error("Error inserting report:", error);
    return null;
  }

  return data;
};

// Function to get all reports
export const getReports = async (): Promise<Report[] | null> => {
  const { data, error } = await supabase.from("community_reports").select("*");

  if (error) {
    console.error("Error fetching reports:", error);
    return null;
  }

  return data;
};
