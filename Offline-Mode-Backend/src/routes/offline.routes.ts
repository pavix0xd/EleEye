import { Router } from "express";
import { storeOfflineReport, syncOfflineReports } from "../controllers/offline.controller";

const router = Router();

// Store offline report locally
router.post("/offline/reports", storeOfflineReport);

// Sync offline reports when online
router.post("/offline/sync", syncOfflineReports);

export default router;
