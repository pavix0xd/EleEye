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
exports.fetchNearbyElephants = void 0;
const elephantService_1 = require("../services/elephantService");
const fetchNearbyElephants = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { latitude, longitude } = req.query;
    if (!latitude || !longitude) {
        res.status(400).json({ error: 'Latitude and longitude are required' });
        return;
    }
    try {
        const elephants = yield (0, elephantService_1.getNearbyElephants)(parseFloat(latitude), parseFloat(longitude));
        res.json(elephants);
    }
    catch (error) {
        if (error instanceof Error) {
            res.status(500).json({ error: error.message });
        }
        else {
            res.status(500).json({ error: 'An unknown error occurred' });
        }
    }
});
exports.fetchNearbyElephants = fetchNearbyElephants;
