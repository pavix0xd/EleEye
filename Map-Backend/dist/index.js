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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const http_1 = require("http");
const socket_io_1 = require("socket.io");
const elephantRoutes_1 = __importDefault(require("./routes/elephantRoutes"));
const elephantService_1 = require("./services/elephantService");
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 5000;
// Create an HTTP server
const server = (0, http_1.createServer)(app);
const io = new socket_io_1.Server(server, {
    cors: { origin: '*' }
});
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use('/elephants', elephantRoutes_1.default);
// WebSocket connection
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);
    socket.on('user_location', (_a) => __awaiter(void 0, [_a], void 0, function* ({ latitude, longitude }) {
        console.log(`User at: ${latitude}, ${longitude}`);
        const nearbyElephants = yield (0, elephantService_1.getNearbyElephants)(latitude, longitude);
        io.emit('elephant_locations', nearbyElephants);
        // Check if an elephant is within 500m
        const closeElephants = nearbyElephants.filter((e) => (0, elephantService_1.calculateDistance)(latitude, longitude, e.latitude, e.longitude) <= 0.5);
        if (closeElephants.length > 0) {
            socket.emit('elephant_alert', { message: 'Elephant detected within 500m!' });
        }
    }));
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
