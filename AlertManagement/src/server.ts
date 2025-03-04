import express = require('express');
import * as http from 'http';
import { Server } from 'socket.io';
import { setupAlertRoutes } from './routes/alertRoutes'; // Import your route
import * as dotenv from 'dotenv';

dotenv.config();  // Load environment variables from .env file

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.json()); // Middleware to parse JSON request bodies

// Set up the route to handle POST /api/alerts
app.use('/api/alerts', setupAlertRoutes(io));

const PORT = process.env.PORT || 5000;  // Use port 5000 or from environment variables
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

