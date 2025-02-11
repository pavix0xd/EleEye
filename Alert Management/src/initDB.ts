// import supabase from "./db";  // Import the Supabase client

// const createTables = async () => {
//   try {
//     // SQL query to create the tables
//     const { data, error } = await supabase.rpc('run_sql', {
//       sql: `
//         CREATE TABLE IF NOT EXISTS alerts (
//           id bigserial PRIMARY KEY,
//           event_type VARCHAR(50),
//           location TEXT,
//           status VARCHAR(20) DEFAULT 'pending',
//           timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//           confidence FLOAT,
//           source VARCHAR(50)
//         );

//         CREATE TABLE IF NOT EXISTS notifications (
//           id bigserial PRIMARY KEY,
//           alert_id INT REFERENCES alerts(id),
//           user_id INT,
//           type VARCHAR(20),
//           sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
//         );
//       `
//     });

//     if (error) {
//       throw error;
//     }
//     console.log("Tables created successfully!");
//   } catch (err) {
//     console.error("Error creating tables:", err);
//   }
// };

// createTables();
