import express from "express";
import { getCities, searchCity } from "../controllers/cityController";

const router = express.Router();

router.get("/cities", getCities);
router.get("/cities/search", searchCity);

export default router;
