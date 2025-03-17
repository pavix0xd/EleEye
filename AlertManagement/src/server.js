"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var express = require("express");
var http = require("http");
var socket_io_1 = require("socket.io");
var alertRoutes_1 = require("./routes/alertRoutes"); // Import your route
var dotenv = require("dotenv");
dotenv.config(); // Load environment variables from .env file
var app = express();
var server = http.createServer(app);
var io = new socket_io_1.Server(server);
app.use(express.json()); // Middleware to parse JSON request bodies
// Set up the route to handle POST /api/alerts
app.use('/api/alerts', (0, alertRoutes_1.setupAlertRoutes)(io));
var PORT = process.env.PORT || 5000; // Use port 5000 or from environment variables
server.listen(PORT, function () {
    console.log("Server is running on port ".concat(PORT));
});
