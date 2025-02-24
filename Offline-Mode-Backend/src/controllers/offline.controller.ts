import { Request, Response } from "express";
import { initLocalDB } from "../db/localDB";
import axios from "axios";
import supabase from "../db/supabase";


// Store detection reports in local SQLite when offline
export const storeOfflineReport = async (req: Request, res: Response) => {
  try {
    const { latitude, longitude, description } = req.body;
    if (!latitude || !longitude) {
      res.status(400).json({ error: "Missing required fields" });
      return; // Remove the 'return res...' and just send response + return
    }

    const db = await initLocalDB();
    await db.run(
      "INSERT INTO offline_reports (latitude, longitude, description) VALUES (?, ?, ?)",
      [latitude, longitude, description]
    );

    res.status(201).json({ message: "Report stored locally (offline mode)." });
  } catch (err) {
    console.error("Error storing offline report:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Sync stored offline reports with Supabase when back online
export const syncOfflineReports = async (req: Request, res: Response) => {
  try {
    const db = await initLocalDB();
    const reports = await db.all("SELECT * FROM offline_reports WHERE synced = 0");

    if (reports.length === 0) {
      res.json({ message: "No unsynced reports to upload." });
      return;
    }

    for (const report of reports) {
      const { data, error } = await supabase
        .from("alerts") 
        .insert([{ 
          latitude: report.latitude, 
          longitude: report.longitude, 
          description: report.description 
        }]);

      if (!error) {
        await db.run("UPDATE offline_reports SET synced = 1 WHERE id = ?", [report.id]);
      } else {
        console.error("Sync failed:", error);
      }
    }

    res.json({ message: `Synced ${reports.length} offline reports successfully.` }); // Fix template literal
  } catch (err) {
    console.error("Error syncing offline reports:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};