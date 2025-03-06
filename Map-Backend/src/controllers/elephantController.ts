import { Request, Response } from 'express';
import { getNearbyElephants } from '../services/elephantService';
import { Elephant } from '../models/elephant'; 

export const fetchNearbyElephants = async (req: Request, res: Response) => {
  const { latitude, longitude } = req.query;

  if (!latitude || !longitude) {
    res.status(400).json({ error: 'Latitude and longitude are required' });
    return;
  }

  try {
    const elephants = await getNearbyElephants(parseFloat(latitude as string), parseFloat(longitude as string));
    res.json(elephants);
  } catch (error) {
    if (error instanceof Error) {
      res.status(500).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'An unknown error occurred' });
    }
  }
};
