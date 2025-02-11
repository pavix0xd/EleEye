import { Request, Response } from "express";
import * as reportService from "../services/report.service";

export const createReport = async (req: Request, res: Response) => {
  try {
    const {latitude, longitude} = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const report = await reportService.createReport({latitude, longitude,});
    return res.status(201).json({ report });
  } catch (err) {
    console.error("Error creating report:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const getReports = async (req: Request, res: Response) => {
  try {
    const reports = await reportService.getReports();
    return res.status(200).json({ reports });
  } catch (err) {
    console.error("Error retrieving reports:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};
