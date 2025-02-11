import { pool} from "../db";
import { Report }from "../models/report.model";

export const createReport = async (report: Report): Promise<Report> => {
    const query = `
        INSERT INTO community_reports (latitude, longitude)
        VALUES ($1, $2)
        RETURNING *;
        `;
    
    const values = [report.latitude, report.latitude];
    const result = await pool.query(query, values);
    return result.rows[0];
};

export const getReports = async(): Promise<Report[]> => {
    const result = await pool.query("SELECT * FROM community_reports;");
    return result.rows;
};