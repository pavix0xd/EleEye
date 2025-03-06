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
exports.deleteReport = exports.getReports = exports.createReport = void 0;
const supabase_1 = __importDefault(require("../db/supabase"));
// Create a report
const createReport = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { latitude, longitude } = req.body;
        if (!latitude || !longitude) {
            return res.status(400).json({ error: "Missing required fields" });
        }
        const { data, error } = yield supabase_1.default
            .from("community_reports")
            .insert([{ latitude, longitude }])
            .select(); // Ensure the inserted row is returned
        if (error)
            throw error;
        return res.status(201).json({ report: data }); // Ensure it's an array
    }
    catch (err) {
        console.error("Error creating report:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});
exports.createReport = createReport;
// Get all reports
const getReports = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { data, error } = yield supabase_1.default
            .from("community_reports")
            .select("*");
        if (error)
            throw error;
        return res.status(200).json({ reports: data });
    }
    catch (err) {
        console.error("Error retrieving reports:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});
exports.getReports = getReports;
const deleteReport = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        // Check if the report exists
        const { data: existingReport, error: fetchError } = yield supabase_1.default
            .from("community_reports")
            .select("id")
            .eq("id", id);
        if (fetchError)
            throw fetchError;
        if (!existingReport || existingReport.length === 0) {
            return res.status(404).json({ error: "Report not found" });
        }
        // Proceed with deletion
        const { error } = yield supabase_1.default
            .from("community_reports")
            .delete()
            .eq("id", id);
        if (error)
            throw error;
        return res.status(200).json({ message: "Marker deleted successfully" });
    }
    catch (err) {
        console.error("Error deleting report:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});
exports.deleteReport = deleteReport;
