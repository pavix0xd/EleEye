import { Request, Response } from "express";
import { getAllCities, searchCities } from "../services/cityService";

export const getCities = async (req: Request, res: Response): Promise<void> => {
  try {
    const cities = await getAllCities();
    res.json(cities); // Make sure this is the final operation
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch cities" });
  }
};

export const searchCity = async (req: Request, res: Response): Promise<void> => {
  const { query } = req.query;
  if (!query) {
    res.status(400).json({ error: "Query is required" });
    return;
  }

  try {
    const results = await searchCities(query as string);
    res.json(results); // Ensure no return statement is used
  } catch (error) {
    res.status(500).json({ error: "Failed to search cities" });
  }
};
