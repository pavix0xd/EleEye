"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http = __importStar(require("http"));
const socket_io_1 = require("socket.io");
const notificationRoutes_1 = require("./routes/notificationRoutes"); // Import the notification routes
const checkFcmRoutes_1 = require("./routes/checkFcmRoutes"); // Import the checkFcm routes
const dotenv = __importStar(require("dotenv"));
dotenv.config(); // Load environment variables
const app = (0, express_1.default)();
const server = http.createServer(app);
const io = new socket_io_1.Server(server);
app.use(express_1.default.json()); // Middleware to parse JSON request bodies
// Set up the route to handle POST /send-notification
app.use('/api/notifications', notificationRoutes_1.notificationRoutes); // Use the notification routes under '/api/notifications'
app.use('/api/checkFcm', checkFcmRoutes_1.checkFcmRoutes); // Use the checkFcm routes under '/api/check-fcm'
// Start the server
const PORT = process.env.PORT || 5004;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
