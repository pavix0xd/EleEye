import express from 'express';
import { fetchNearbyElephants } from '../controllers/elephantController';

const router = express.Router();

router.get('/nearby', fetchNearbyElephants);

export default router;
