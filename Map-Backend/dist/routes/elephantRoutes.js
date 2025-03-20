"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const elephantController_1 = require("../controllers/elephantController");
const router = express_1.default.Router();
router.get('/nearby', elephantController_1.fetchNearbyElephants);
exports.default = router;
