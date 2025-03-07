import { Router, Request, Response } from 'express';
import { NotificationService } from '../services/notificationService';


const router = Router();

// Create an instance of the NotificationService
const notificationService = new NotificationService();

// Define the endpoint for sending notifications
router.post('/send-notification', async (req: Request, res: Response) => {
  const { userId, title, message } = req.body;

  try {
    // Validate the input
    if (!userId || !title || !message) {
      return res.status(400).json({ error: 'userId, title, and message are required.' });
    }

    // Call the notification service to send the push notification
    const result = await notificationService.sendPushNotification(userId, title, message);

    // Send the success response
    return res.status(200).json(result);
  } catch (error) {
    console.error('Error in send-notification route:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

export { router as notificationRoutes };
