import express from "express";
import mongoose from "mongoose";
import helmet from "helmet";
import cors from "cors";
import userRoutes from "./routes/userRoutes.js";

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// MongoDB connection from environment variables
const username = process.env.MONGO_USERNAME || "admin";
const password = process.env.MONGO_PASSWORD || "password123";
const host = process.env.MONGO_HOST || "127.0.0.1";
const port = process.env.MONGO_PORT || 27017;
const dbName = process.env.MONGO_DBNAME || "testdb";

const MONGO_URI = `mongodb://${username}:${password}@${host}:${port}/${dbName}?authSource=admin`;

// Connect to MongoDB
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("✅ Connected to MongoDB"))
  .catch(err => {
    console.error("❌ MongoDB Connection Error:", err);
    process.exit(1); // exit if DB fails
  });

// Routes
app.use("/api/users", userRoutes);

// Health check
app.get("/healthz", (req, res) => {
  res.json({ status: "ok" });
});

// Start server
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("🛑 SIGINT received, shutting down server...");
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log("✅ MongoDB connection closed");
      process.exit(0);
    });
  });
});
process.on("SIGTERM", () => {
  console.log("🛑 SIGTERM received, shutting down server...");
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log("✅ MongoDB connection closed");
      process.exit(0);
    });
  });
});
