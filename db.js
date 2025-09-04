const { MongoClient } = require('mongodb');

const username = process.env.MONGO_USERNAME;
const password = process.env.MONGO_PASSWORD;
const host = process.env.MONGO_HOST;
const port = process.env.MONGO_PORT || 27017;
const uri = `mongodb://${username}:${password}@${host}:${port}/?authSource=admin`;
const client = new MongoClient(uri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function connectDB() {
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB successfully!');
    return client.db('mydatabase');
  } catch (err) {
    console.error('❌ MongoDB connection failed:', err);
    process.exit(1);
  }
}

module.exports = { connectDB };
