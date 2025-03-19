import { Router } from "express";
import * as reportController from "../controllers/report.controller";

const router = Router();

// Route to create a new community report
router.post("/reports", async (req, res, next) => {
  try {
    await reportController.createReport(req, res);
  } catch (error) {
    next(error); // Pass errors to Express error handler
  }
});

// Route to fetch all community reports
router.get("/reports", async (req, res, next) => {
  try {
    await reportController.getReports(req, res);
  } catch (error) {
    next(error);
  }
});

// Route to delete a specific community report by ID
router.delete("/reports/:id", async (req, res, next) => {
  try {
    await reportController.deleteReport(req, res);
  } catch (error) {
    next(error);
  }
});


export default router;


