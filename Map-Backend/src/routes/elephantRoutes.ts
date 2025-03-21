import express from 'express';
import { fetchNearbyElephants } from '../controllers/elephantController';

const router = express.Router();

// Route to fetch elephants near a given location (latitude & longitude)
router.get('/nearby', fetchNearbyElephants);

export default router;
