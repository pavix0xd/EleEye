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
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupAlertRoutes = setupAlertRoutes;
var express = require("express");
var db_1 = require("../db"); // Import the Supabase client
// Define the alertRoutes function to accept `io`
var router = express.Router();
function setupAlertRoutes(io) {
    var _this = this;
    // Create a new alert
    router.post("/", function (req, res) { return __awaiter(_this, void 0, void 0, function () {
        var _a, event_type, location, confidence, source, _b, data, error, err_1;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    _a = req.body, event_type = _a.event_type, location = _a.location, confidence = _a.confidence, source = _a.source;
                    _c.label = 1;
                case 1:
                    _c.trys.push([1, 3, , 4]);
                    return [4 /*yield*/, db_1.default
                            .from("alerts")
                            .insert([{
                                event_type: event_type,
                                location: location,
                                confidence: confidence,
                                source: source
                            }])
                            .single()];
                case 2:
                    _b = _c.sent(), data = _b.data, error = _b.error;
                    // Check for Supabase errors
                    if (error) {
                        console.error("Supabase Error:", error); // Log the Supabase error
                        throw error; // Rethrow to be caught in the outer catch block
                    }
                    // Emit real-time alert (WebSockets)
                    io.emit("newAlert", data);
                    // Send back the inserted data
                    res.json(data);
                    return [3 /*break*/, 4];
                case 3:
                    err_1 = _c.sent();
                    // General error handling (catching any type of error)
                    console.error("Error creating alert:", err_1 instanceof Error ? err_1.message : err_1); // Log the detailed error
                    res.status(500).json({ error: "An error occurred while creating the alert" });
                    return [3 /*break*/, 4];
                case 4: return [2 /*return*/];
            }
        });
    }); });
    return router;
}
