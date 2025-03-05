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
exports.getReports = exports.createReport = void 0;
const supabase_1 = __importDefault(require("../db/supabase"));
// Function to create a new report
const createReport = (report) => __awaiter(void 0, void 0, void 0, function* () {
    const { data, error } = yield supabase_1.default
        .from("community_reports")
        .insert([
        {
            latitude: report.latitude,
            longitude: report.longitude,
        },
    ])
        .select("*") // This ensures that we return the inserted data
        .single(); // Ensures we return a single object instead of an array
    if (error) {
        console.error("Error inserting report:", error);
        return null;
    }
    return data;
});
exports.createReport = createReport;
// Function to get all reports
const getReports = () => __awaiter(void 0, void 0, void 0, function* () {
    const { data, error } = yield supabase_1.default.from("community_reports").select("*");
    if (error) {
        console.error("Error fetching reports:", error);
        return null;
    }
    return data;
});
exports.getReports = getReports;
