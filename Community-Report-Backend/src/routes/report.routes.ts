import { Router } from "express";
import * as reportController from "../controllers/report.controller";

const router = Router();

router.post("/reports", async (req, res, next) => {
  try {
    await reportController.createReport(req, res);
  } catch (error) {
    next(error); // Pass errors to Express error handler
  }
});

router.get("/reports", async (req, res, next) => {
  try {
    await reportController.getReports(req, res);
  } catch (error) {
    next(error);
  }
});

export default router;


