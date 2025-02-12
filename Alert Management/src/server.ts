import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import { setupAlertRoutes } from './routes/alertRoutes';  // Import your alert routes
import { NotificationService } from './services/notificationService';  // Import NotificationService
import dotenv from 'dotenv';

dotenv.config();  // Load environment variables from .env file

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const notificationService = new NotificationService();  // Initialize NotificationService

app.use(express.json());  // Middleware to parse JSON request bodies

// Set up the route to handle POST /api/alerts
app.use('/api/alerts', setupAlertRoutes(io));

// New route to handle sending notifications
app.post('/send-notification', async (req, res) => {
  const { userId, message } = req.body;  // userId is the FCM token

  try {
    await notificationService.sendPushNotification(userId, message);
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    res.status(500).send('Error sending notification');
  }
});

const PORT = process.env.PORT || 5000;  // Use port 5000 or from environment variables
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
