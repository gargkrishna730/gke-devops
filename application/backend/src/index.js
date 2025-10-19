const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'Backend API is healthy', timestamp: new Date().toISOString() });
});

// API endpoints
app.get('/api/v1/data', (req, res) => {
  res.json({
    message: 'Data from backend API',
    data: [
      { id: 1, name: 'Item 1', description: 'First item' },
      { id: 2, name: 'Item 2', description: 'Second item' },
      { id: 3, name: 'Item 3', description: 'Third item' }
    ],
    timestamp: new Date().toISOString()
  });
});

app.get('/api/v1/status', (req, res) => {
  res.json({
    service: 'wobot-backend',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime()
  });
});

app.post('/api/v1/echo', (req, res) => {
  const { message } = req.body;
  res.json({
    received: message,
    echoed: message,
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
