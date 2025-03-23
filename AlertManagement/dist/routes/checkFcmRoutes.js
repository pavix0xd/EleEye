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
exports.checkFcmRoutes = void 0;
// checkFcmRoutes.ts
const express_1 = require("express");
const checkFcmService_1 = require("../services/checkFcmService");
const router = (0, express_1.Router)();
exports.checkFcmRoutes = router;
const CheckFcmService = new checkFcmService_1.checkFcmService();
router.post('/checkAndUpdatefcm', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { userId, fcmToken } = req.body;
    if (!userId || !fcmToken) {
        return res.status(400).json({ message: 'userId and fcmToken are required' });
    }
    try {
        const result = yield CheckFcmService.checkAndUpdateFcmToken(userId, fcmToken);
        return res.json({ success: true, message: result });
    }
    catch (error) {
        return res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
}));
