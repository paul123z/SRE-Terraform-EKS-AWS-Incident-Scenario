const express = require('express');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Global variables for incident simulation
let failureMode = process.env.FAILURE_MODE || 'none';
let memoryLeak = [];
let cpuIntensive = false;

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'SRE Incident Demo App',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    failureMode: failureMode,
    status: 'healthy'
  });
});

app.get('/health', (req, res) => {
  // Simulate different failure modes
  switch (failureMode) {
    case 'health_failure':
      res.status(503).json({ error: 'Health check failed', timestamp: new Date().toISOString() });
      break;
    case 'slow_response':
      setTimeout(() => {
        res.json({ status: 'healthy', timestamp: new Date().toISOString() });
      }, 10000); // 10 second delay
      break;
    default:
      res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  }
});

app.get('/api/data', async (req, res) => {
  try {
    // Simulate external API call
    const response = await axios.get('https://httpbin.org/json', { timeout: 5000 });
    res.json({
      success: true,
      data: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

app.get('/api/stress', (req, res) => {
  // Simulate CPU intensive operation
  if (cpuIntensive) {
    const start = Date.now();
    let result = 0;
    for (let i = 0; i < 1000000000; i++) {
      result += Math.sqrt(i);
    }
    const duration = Date.now() - start;
    res.json({ result, duration, timestamp: new Date().toISOString() });
  } else {
    res.json({ message: 'CPU stress test disabled', timestamp: new Date().toISOString() });
  }
});

app.post('/api/failure-mode', (req, res) => {
  const { mode } = req.body;
  failureMode = mode || 'none';
  res.json({ 
    message: `Failure mode set to: ${failureMode}`,
    timestamp: new Date().toISOString()
  });
});

app.post('/api/memory-leak', (req, res) => {
  const { enable } = req.body;
  if (enable) {
    // Simulate memory leak
    setInterval(() => {
      memoryLeak.push(new Array(1000000).fill('leak'));
    }, 1000);
    res.json({ message: 'Memory leak enabled', timestamp: new Date().toISOString() });
  } else {
    memoryLeak = [];
    res.json({ message: 'Memory leak disabled', timestamp: new Date().toISOString() });
  }
});

app.post('/api/cpu-stress', (req, res) => {
  const { enable } = req.body;
  cpuIntensive = enable;
  res.json({ 
    message: `CPU stress test ${enable ? 'enabled' : 'disabled'}`,
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`SRE Demo App running on port ${PORT}`);
  console.log(`Failure mode: ${failureMode}`);
}); 