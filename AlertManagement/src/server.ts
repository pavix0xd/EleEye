import express from 'express';
import * as http from 'http';
import { notificationRoutes} from './routes/notificationRoutes'; // Import the notification routes
import { alertRoutes } from './routes/alertRoutes'; // Import the alert routes
import { checkFcmRoutes } from './routes/checkFcmRoutes'; // Import the checkFcm routes
import * as dotenv from 'dotenv';

dotenv.config();  // Load environment variables

const app = express();
const server = http.createServer(app);


app.use(express.json()); // Middleware to parse JSON request bodies

// Set up the route to handle POST /send-notification
app.use('/api/alerts', alertRoutes);  // Use the notification routes under '/api/notifications'
app.use('/api/notifications', notificationRoutes);  // Use the notification routes under '/api/notifications'
app.use('/api/checkFcm', checkFcmRoutes);  // Use the checkFcm routes under '/api/check-fcm'

// Start the server
const PORT = process.env.PORT || 5004;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
