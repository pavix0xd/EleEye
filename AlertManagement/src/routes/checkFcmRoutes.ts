// checkFcmRoutes.ts
import express from 'express';
import { checkAndUpdateFcmToken } from '../services/notificationService';

const router = express.Router();

router.post('/check-fcm', async (req, res) => {
    const { userId, fcmToken } = req.body;
    
    if (!userId || !fcmToken) {
        return res.status(400).json({ message: 'userId and fcmToken are required' });
    }
    
    try {
        const result = await checkAndUpdateFcmToken(userId, fcmToken);
        return res.json({ success: true, message: result });
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
});

export default router;