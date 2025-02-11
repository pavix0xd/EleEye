import {Pool} from "pg";
import dotenv from "dotenv";

dotenv.config();

export const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT)
});

pool.connect((err) => {
    if(err) {
        console.log("Error connecting to the database", err);
    }
    else {
        console.log("Connected to the database");
    }
});


