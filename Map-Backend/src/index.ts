import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createServer, Server as HttpServer } from 'http';
import { Server } from 'socket.io';
import elephantRoutes from './routes/elephantRoutes';
import supabase from './utils/supabaseClient';
import { Elephant } from './models/elephant';
import { getNearbyElephants, calculateDistance } from './services/elephantService';



dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Create an HTTP server
const server: HttpServer = createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(cors());
app.use(express.json());
app.use('/elephants', elephantRoutes);

// WebSocket connection
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('user_location', async ({ latitude, longitude }) => {
    console.log(`User at: ${latitude}, ${longitude}`);
    const nearbyElephants = await getNearbyElephants(latitude, longitude);
    
    io.emit('elephant_locations', nearbyElephants);

    // Check if an elephant is within 500m
    const closeElephants = nearbyElephants.filter((e: Elephant) => 
      calculateDistance(latitude, longitude, e.latitude, e.longitude) <= 0.5
    );
    
    if (closeElephants.length > 0) {
      socket.emit('elephant_alert', { message: 'Elephant detected within 500m!' });
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});