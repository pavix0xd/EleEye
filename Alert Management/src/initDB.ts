import pool from "./db";

const createTables = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS alerts (
        id SERIAL PRIMARY KEY,
        event_type VARCHAR(50),
        location TEXT,
        status VARCHAR(20) DEFAULT 'pending',
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        confidence FLOAT,
        source VARCHAR(50)
      );

      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        alert_id INT REFERENCES alerts(id),
        user_id INT,
        type VARCHAR(20),
        sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("Tables created successfully!");
  } catch (err) {
    console.error(" Error creating tables:", err);
  } finally {
    pool.end();
  }
};

createTables();
