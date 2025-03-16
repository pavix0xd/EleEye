import express from "express";
import cors from "cors";
import cityRoutes from "./routes/cityRoutes";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api", cityRoutes);

export default app;
