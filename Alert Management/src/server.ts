import express from "express";
import { Server } from "socket.io";
import http from "http";
import { setupAlertRoutes } from "./routes/alertRoutes";  // Import the routes

const app = express();
const server = http.createServer(app);  // Use HTTP server with Express
const io = new Server(server, {
  cors: {
    origin: "*",  // Allow all connections
  },
});

// Middleware
app.use(express.json());  // Middleware to parse JSON requests

// Use the alert routes with WebSocket integration
app.use("/api/alerts", setupAlertRoutes(io));

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
