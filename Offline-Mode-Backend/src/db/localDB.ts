import sqlite3 from "sqlite3";
import { open } from "sqlite";

// Function to open the SQLite database
export const initLocalDB = async () => {
  return open({
    filename: "./offline_reports.db", // Database file
    driver: sqlite3.Database, // SQLite driver
  });
};

// Function to create the reports table
export const setupDatabase = async () => {
  const db = await initLocalDB();
  await db.exec(`
    CREATE TABLE IF NOT EXISTS offline_reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude DECIMAL(9, 6) NOT NULL,
      longitude DECIMAL(9, 6) NOT NULL,
      description TEXT,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      synced BOOLEAN DEFAULT 0
    );
  `);
};


