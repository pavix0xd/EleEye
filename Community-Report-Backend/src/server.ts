import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import bodyParser from "body-parser";
import reportRoutes from "./routes/report.routes";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use("/api", reportRoutes);

// Server Start
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
