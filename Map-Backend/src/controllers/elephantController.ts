import { Request, Response } from 'express';
import { getNearbyElephants } from '../services/elephantService';
import { Elephant } from '../models/elephant'; 

// Controller function to fetch nearby elephants based on user's location
export const fetchNearbyElephants = async (req: Request, res: Response) => {
  const { latitude, longitude } = req.query; // Extract latitude and longitude from query parameters

  // Validate that both latitude and longitude are provided
  if (!latitude || !longitude) {
    res.status(400).json({ error: 'Latitude and longitude are required' });
    return;
  }

  try {
    const elephants = await getNearbyElephants(parseFloat(latitude as string), parseFloat(longitude as string)); // Fetch nearby elephants using the service function
    // Send the retrieved elephant data as a response
    res.json(elephants);
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'An unknown error occurred' });
    }
  }
};
