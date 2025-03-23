"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationRoutes = void 0;
const express_1 = require("express");
const notificationService_1 = require("../services/notificationService");
const router = (0, express_1.Router)();
exports.notificationRoutes = router;
// Create an instance of the NotificationService
const notificationService = new notificationService_1.NotificationService();
// Define the endpoint for sending notifications
router.post('/send-notification', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { title, message, latitude, longitude } = req.body;
    try {
        // Validate the input
        if (!title || !message || !latitude || !longitude) {
            return res.status(400).json({ error: 'title, message, latitude, and longitude are required.' });
        }
        // Call the notification service to send the push notification
        const result = yield notificationService.sendPushNotificationToAllUsers(title, message, latitude, longitude);
        // Send the success response
        return res.status(200).json(result);
    }
    catch (error) {
        console.error('Error in send-notification route:', error);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
}));
