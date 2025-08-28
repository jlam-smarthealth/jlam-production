/**
 * JLAM Passage Authentication Service
 * Forward Auth Service for Traefik API Gateway
 * 
 * This service validates biometric authentication via Passage
 * and provides user context to backend services.
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { Passage } from '@passageidentity/passage-node';
import { Authentikit } from '@passageidentity/authentikit';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Initialize Passage and Authentikit
const passage = new Passage({
  appID: process.env.PASSAGE_APP_ID,
  apiKey: process.env.PASSAGE_API_KEY,
});

const authentikit = new Authentikit({
  appId: process.env.PASSAGE_APP_ID,
  apiKey: process.env.PASSAGE_API_KEY,
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:5173'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'jlam-passage-auth',
    timestamp: new Date().toISOString(),
    passage_configured: !!(process.env.PASSAGE_APP_ID && process.env.PASSAGE_API_KEY)
  });
});

// Forward Auth endpoint for Traefik
app.all('/auth', async (req, res) => {
  try {
    console.log('🔐 Auth request received:', {
      method: req.method,
      url: req.url,
      headers: {
        authorization: req.headers.authorization ? '***masked***' : 'none',
        'user-agent': req.headers['user-agent']
      }
    });

    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('❌ No valid authorization header found');
      return res.status(401).json({ 
        error: 'No authorization token provided',
        required: 'Bearer token in Authorization header'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Validate token with Passage
    const user = await passage.authenticateJWT(token);
    console.log('✅ User authenticated:', {
      id: user.id,
      email: user.email,
      created_at: user.created_at
    });

    // Set headers for downstream services (Traefik forwards these)
    res.setHeader('X-Auth-User', user.email);
    res.setHeader('X-User-ID', user.id);
    res.setHeader('X-User-Email', user.email);
    res.setHeader('X-Auth-Method', 'passage-biometric');
    res.setHeader('X-Auth-Timestamp', new Date().toISOString());
    
    // Add user metadata if available
    if (user.user_metadata) {
      res.setHeader('X-User-Roles', JSON.stringify(user.user_metadata.roles || ['user']));
      res.setHeader('X-User-Subscription', user.user_metadata.subscription || 'free');
    } else {
      res.setHeader('X-User-Roles', JSON.stringify(['user']));
      res.setHeader('X-User-Subscription', 'free');
    }

    // Log successful authentication
    console.log('🎉 Authentication successful for:', user.email);
    
    res.status(200).json({ 
      status: 'authenticated',
      user: {
        id: user.id,
        email: user.email,
        authenticated_at: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Authentication failed:', {
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });

    // Return 401 for any authentication failure
    res.status(401).json({
      error: 'Authentication failed',
      message: process.env.NODE_ENV === 'development' ? error.message : 'Invalid credentials'
    });
  }
});

// Test endpoint to validate Passage configuration
app.get('/test-config', async (req, res) => {
  try {
    if (!process.env.PASSAGE_APP_ID || !process.env.PASSAGE_API_KEY) {
      return res.status(500).json({
        error: 'Passage not configured',
        missing: [
          !process.env.PASSAGE_APP_ID && 'PASSAGE_APP_ID',
          !process.env.PASSAGE_API_KEY && 'PASSAGE_API_KEY'
        ].filter(Boolean)
      });
    }

    // Test basic Passage connection
    const appInfo = await passage.getApp();
    res.json({
      status: 'configured',
      app_id: process.env.PASSAGE_APP_ID,
      app_name: appInfo.name,
      message: 'Passage is properly configured'
    });
  } catch (error) {
    res.status(500).json({
      error: 'Passage configuration error',
      message: error.message
    });
  }
});

// Error handler
app.use((error, req, res, next) => {
  console.error('💥 Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 JLAM Passage Authentication Service started');
  console.log(`📡 Listening on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔐 Passage App ID: ${process.env.PASSAGE_APP_ID || 'NOT SET'}`);
  console.log(`🔑 Passage API Key: ${process.env.PASSAGE_API_KEY ? '✅ SET' : '❌ NOT SET'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🧪 Test config: http://localhost:${PORT}/test-config`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  process.exit(0);
});