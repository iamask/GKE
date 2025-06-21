const express = require('express');
const { MongoClient } = require('mongodb');
const app = express();
const PORT = process.env.PORT || 3000;

// MongoDB connection configuration
const MONGO_HOST = process.env.MONGO_HOST || 'localhost';
const MONGO_PORT = process.env.MONGO_PORT || '27017';
const MONGO_DATABASE = process.env.MONGO_DATABASE || 'express_app';
const MONGO_USERNAME = process.env.MONGO_USERNAME || 'root';
const MONGO_PASSWORD = process.env.MONGO_PASSWORD || 'password';
const MONGO_AUTH_SOURCE = process.env.MONGO_AUTH_SOURCE || 'admin';

// MongoDB connection string
const mongoUrl = `mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DATABASE}?authSource=${MONGO_AUTH_SOURCE}`;

// MongoDB client
let mongoClient;
let db;

// Connect to MongoDB
async function connectToMongo() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    mongoClient = new MongoClient(mongoUrl);
    await mongoClient.connect();
    db = mongoClient.db(MONGO_DATABASE);
    
    // Initialize demo data if collection is empty
    const collection = db.collection('messages');
    const count = await collection.countDocuments();
    
    if (count === 0) {
      console.log('📝 Initializing demo data...');
      await collection.insertOne({
        message: 'hello from mongo',
        timestamp: new Date(),
        created: true
      });
      console.log('✅ Demo data initialized');
    }
    
    console.log('✅ Connected to MongoDB successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
  }
}

// Middleware to parse JSON
app.use(express.json());

// Basic route
app.get('/', (req, res) => {
  res.json({
    message: 'Hello World from Express.js on GKE!',
    timestamp: new Date().toISOString(),
    pod: process.env.HOSTNAME || 'unknown',
    environment: process.env.NODE_ENV || 'development',
    mongodb: db ? 'connected' : 'disconnected'
  });
});

// MongoDB demo endpoint
app.get('/mongo', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({
        error: 'MongoDB not connected',
        timestamp: new Date().toISOString()
      });
    }

    const collection = db.collection('messages');
    const data = await collection.findOne({});
    
    res.json({
      message: data ? data.message : 'No data found',
      timestamp: new Date().toISOString(),
      pod: process.env.HOSTNAME || 'unknown',
      mongodb: 'connected',
      collection: 'messages'
    });
  } catch (error) {
    console.error('❌ MongoDB query error:', error);
    res.status(500).json({
      error: 'Database error',
      timestamp: new Date().toISOString()
    });
  }
});

// MongoDB validation endpoint - fetches the specific entry we added
app.get('/mongo-validate', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({
        error: 'MongoDB not connected',
        timestamp: new Date().toISOString()
      });
    }

    const collection = db.collection('messages');
    
    // Find the specific entry we added
    const data = await collection.findOne({
      message: 'Hello World from Express.js and Mongo'
    });
    
    if (data) {
      res.json({
        success: true,
        message: '✅ Response from MongoDB!',
        data: {
          message: data.message,
          timestamp: data.timestamp,
          source: data.source,
          _id: data._id
        },
        pod: process.env.HOSTNAME || 'unknown',
        mongodb: 'connected',
        collection: 'messages',
        query: 'Found specific entry: "Hello World from Express.js and Mongo"'
      });
    } else {
      res.json({
        success: false,
        message: '❌ Entry not found in MongoDB',
        data: null,
        pod: process.env.HOSTNAME || 'unknown',
        mongodb: 'connected',
        collection: 'messages',
        query: 'Looking for: "Hello World from Express.js and Mongo"'
      });
    }
  } catch (error) {
    console.error('❌ MongoDB validation error:', error);
    res.status(500).json({
      error: 'Database error',
      timestamp: new Date().toISOString()
    });
  }
});

// Health check endpoint for Kubernetes
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    mongodb: db ? 'connected' : 'disconnected'
  });
});

// Ready check endpoint for Kubernetes
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString(),
    mongodb: db ? 'connected' : 'disconnected'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Health check available at http://localhost:${PORT}/health`);
  console.log(`✅ Ready check available at http://localhost:${PORT}/ready`);
  console.log(`🗄️  MongoDB demo available at http://localhost:${PORT}/mongo`);
  console.log(`🔍 MongoDB validation available at http://localhost:${PORT}/mongo-validate`);
  
  // Connect to MongoDB
  await connectToMongo();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully...');
  if (mongoClient) {
    await mongoClient.close();
  }
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 Received SIGINT, shutting down gracefully...');
  if (mongoClient) {
    await mongoClient.close();
  }
  process.exit(0);
}); 