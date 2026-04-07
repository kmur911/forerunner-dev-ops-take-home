const express = require("express"); // import the application server framework
const { Pool } = require("pg"); // Import the PostgreSQL library

var args = process.argv.slice(2);
const debugOn = args[0] === "--debug";

const app = express();
// get environment variables
const { PORT: port, PG_USER: user, PG_PASSWORD: password } = process.env;

const pool = new Pool({
  user,
  password,
  host: "db",
  port: 5432,
});

const maximumStartupTime = 120_000; // 2 minutes
const minimumStartupTime = 60_000; // 1 minute
const startupTimeRequired =
  Math.floor(Math.random() * (maximumStartupTime - minimumStartupTime)) + minimumStartupTime;

// Track the application start time
const startTime = Date.now();

app.get("/healthcheck", (req, res) => {
  if(debugOn) {
    console.debug(`Healthcheck called with headers ${JSON.stringify(req.headers)}`);
  }

  // Calculate the time elapsed since the application started (in milliseconds)
  const elapsedTime = Date.now() - startTime;

  if (elapsedTime < startupTimeRequired) {
    // If less than the required startup time has passed, return a 503
    res.status(503).send("Service Unavailable - Application Starting");
  } else {
    // Attempt to access the database
    pool.query("SELECT 1", (error, result) => {
      if (error) {
        // If an error occurs, return a 503
        res.status(503).send("Database Connection Error");
      } else {
        // If the query is successful, return a 200
        res.status(200).send("Healthcheck OK");
      }
    });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});