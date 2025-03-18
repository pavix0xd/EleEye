// checkFcmRoutes.ts
import { Router, Request, Response } from 'express';
import { checkFcmService } from '../services/checkFcmService';

const router = Router();

const CheckFcmService = new checkFcmService ();

router.post('/check-fcm', async (req, res) => {
    const { userId, fcmToken } = req.body;
    
    if (!userId || !fcmToken) {
        return res.status(400).json({ message: 'userId and fcmToken are required' });
    }
    
    try {
        const result = await CheckFcmService.checkAndUpdateFcmToken(userId, fcmToken);
        return res.json({ success: true, message: result });
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
});

export default router;