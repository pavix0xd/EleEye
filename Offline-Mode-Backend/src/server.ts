import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import bodyParser from "body-parser";
import offlineRoutes from "./routes/offline.routes";
import { setupDatabase } from "./db/localDB";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Setup database on startup
setupDatabase();

// Routes
app.use("/api", offlineRoutes);

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
