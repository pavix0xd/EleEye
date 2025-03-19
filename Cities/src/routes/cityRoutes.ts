import express from "express";
import { getCities, searchCity } from "../controllers/cityController";

const router = express.Router();

// Route to get the list of all cities
router.get("/cities", getCities);

// Route to search for cities based on a query parameter
router.get("/cities/search", searchCity);

export default router;
