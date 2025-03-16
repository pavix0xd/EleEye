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
exports.searchCity = exports.getCities = void 0;
const cityService_1 = require("../services/cityService");
const getCities = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const cities = yield (0, cityService_1.getAllCities)();
        res.json(cities); // Make sure this is the final operation
    }
    catch (error) {
        res.status(500).json({ error: "Failed to fetch cities" });
    }
});
exports.getCities = getCities;
const searchCity = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { query } = req.query;
    if (!query) {
        res.status(400).json({ error: "Query is required" });
        return;
    }
    try {
        const results = yield (0, cityService_1.searchCities)(query);
        res.json(results); // Ensure no return statement is used
    }
    catch (error) {
        res.status(500).json({ error: "Failed to search cities" });
    }
});
exports.searchCity = searchCity;
