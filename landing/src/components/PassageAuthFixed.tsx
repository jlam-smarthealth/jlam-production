/**
 * Corrected Passage Authentication Component for JLAM Platform
 * Using the proper @passageidentity/passage-js for actual biometric authentication
 * (Authentikit is for readiness testing only)
 */

import React, { useEffect, useState } from 'react';
import { Passage } from '@passageidentity/passage-js';
import './PassageAuth.css';

interface PassageAuthFixedProps {
  appId: string;
  onAuthSuccess?: (user: any) => void;
  onAuthError?: (error: any) => void;
}

export const PassageAuthFixed: React.FC<PassageAuthFixedProps> = ({
  appId,
  onAuthSuccess,
  onAuthError
}) => {
  const [passage, setPassage] = useState<Passage | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Initialize Passage
  useEffect(() => {
    const initPassage = async () => {
      try {
        console.log('🔐 Initializing Passage with App ID:', appId);
        
        const p = new Passage(appId);
        setPassage(p);
        setIsLoaded(true);

        // Check if user is already authenticated
        try {
          const isAuth = await p.session.authGuard();
          if (isAuth) {
            const userInfo = await p.currentUser.userInfo();
            console.log('🎉 User already authenticated:', userInfo);
            setIsAuthenticated(true);
            setUser(userInfo);
            onAuthSuccess?.(userInfo);
          }
        } catch (authError) {
          // User not authenticated - this is normal
          console.log('ℹ️ User not currently authenticated');
        }

      } catch (error) {
        console.error('❌ Failed to initialize Passage:', error);
        setError('Failed to initialize authentication');
        onAuthError?.(error);
      }
    };

    if (appId && appId !== 'app_temp_development_testing') {
      initPassage();
    } else {
      console.warn('⚠️ Using temporary App ID - real authentication disabled');
      setError('Using temporary configuration. Please configure real Passage credentials.');
      setIsLoaded(true);
    }
  }, [appId, onAuthSuccess, onAuthError]);

  // Handle authentication (sign in)
  const handleAuthenticate = async () => {
    if (!passage) {
      setError('Passage not initialized');
      return;
    }

    // Check if we're using placeholder credentials
    if (appId === 'kR9BG4Wh0NqoQQKpYdwJPefN') {
      setError('Demo mode: Please configure real Passage API credentials to test actual biometric authentication. Check your Passage console at https://console.passage.id/');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      console.log('🔐 Starting passkey sign-in flow...');
      
      // Sign in with passkey (no email required for conditional mediation)
      const authResult = await passage.passkey.login(null, { 
        isConditionalMediation: true 
      });
      
      console.log('✅ Authentication successful:', authResult);
      
      // Get user info after successful login
      const userInfo = await passage.currentUser.userInfo();
      setIsAuthenticated(true);
      setUser(userInfo);
      onAuthSuccess?.(userInfo);

    } catch (error: any) {
      console.error('❌ Authentication failed:', error);
      let errorMessage = error.message || 'Authentication failed';
      
      // Provide helpful error messages for common issues
      if (errorMessage.includes('record not found')) {
        errorMessage = 'No user found. Please register first or check your Passage app configuration.';
      } else if (errorMessage.includes('user canceled')) {
        errorMessage = 'Authentication cancelled by user.';
      } else if (errorMessage.includes('not supported')) {
        errorMessage = 'Passkeys not supported on this device/browser.';
      }
      
      setError(errorMessage);
      onAuthError?.(error);
    } finally {
      setIsLoading(false);
    }
  };

  // Handle registration
  const handleRegister = async () => {
    if (!passage) {
      setError('Passage not initialized');
      return;
    }

    // Check if we're using placeholder credentials
    if (appId === 'kR9BG4Wh0NqoQQKpYdwJPefN') {
      setError('Demo mode: Please configure real Passage API credentials to test actual biometric registration. Check your Passage console at https://console.passage.id/');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      console.log('📝 Starting passkey registration flow...');
      
      // For demo purposes, use a demo email
      // In production, you'd collect this from user
      const email = `test.${Date.now()}@jlam.nl`;
      
      const regResult = await passage.passkey.register(email);
      
      console.log('✅ Registration successful:', regResult);
      
      // Get user info after successful registration
      const userInfo = await passage.currentUser.userInfo();
      setIsAuthenticated(true);
      setUser(userInfo);
      onAuthSuccess?.(userInfo);

    } catch (error: any) {
      console.error('❌ Registration failed:', error);
      let errorMessage = error.message || 'Registration failed';
      
      // Provide helpful error messages
      if (errorMessage.includes('user canceled')) {
        errorMessage = 'Registration cancelled by user.';
      } else if (errorMessage.includes('not supported')) {
        errorMessage = 'Passkeys not supported on this device/browser.';
      } else if (errorMessage.includes('already exists')) {
        errorMessage = 'User already exists. Try signing in instead.';
      }
      
      setError(errorMessage);
      onAuthError?.(error);
    } finally {
      setIsLoading(false);
    }
  };

  // Handle logout
  const handleLogout = async () => {
    if (!passage) return;

    try {
      await passage.session.signOut();
      setIsAuthenticated(false);
      setUser(null);
      console.log('✅ Logout successful');
    } catch (error: any) {
      console.error('❌ Logout failed:', error);
      setError(error.message || 'Logout failed');
    }
  };

  // Loading state
  if (!isLoaded && appId !== 'app_temp_development_testing') {
    return (
      <div className="passage-auth-loading">
        <div className="loading-content">
          <div className="loading-spinner"></div>
          <p>Loading biometric authentication...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="passage-auth-error">
        <div className="error-content">
          <h3>🔒 Authentication Error</h3>
          <p>{error}</p>
          {appId === 'app_temp_development_testing' && (
            <div className="dev-message">
              <p><strong>Development Mode:</strong> Please configure real Passage credentials in .env.dev</p>
            </div>
          )}
          <button 
            onClick={() => window.location.reload()} 
            className="retry-button"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  // Authenticated state
  if (isAuthenticated && user) {
    return (
      <div className="passage-auth-success">
        <div className="success-content">
          <h3>🎉 Welcome to JLAM!</h3>
          <p>Successfully authenticated with biometric login</p>
          <div className="user-info">
            <p><strong>User ID:</strong> {(user as any).id || 'N/A'}</p>
            <p><strong>Email:</strong> {(user as any).email || 'N/A'}</p>
            <p><strong>Phone:</strong> {(user as any).phone || 'Not provided'}</p>
          </div>
          <div className="auth-actions">
            <button 
              onClick={() => window.location.href = '/dashboard'} 
              className="continue-button"
            >
              Continue to Platform →
            </button>
            <button 
              onClick={handleLogout} 
              className="logout-button"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Authentication options
  return (
    <div className="passage-auth-container">
      <div className="auth-content">
        <div className="auth-header">
          <h2>🔐 Secure Login</h2>
          <p>Use your biometric authentication to access JLAM</p>
        </div>
        
        <div className="auth-options">
          <button 
            onClick={handleAuthenticate}
            disabled={isLoading}
            className="auth-button primary"
          >
            {isLoading ? '🔄 Authenticating...' : '🔓 Sign In with Passkey'}
          </button>

          <button 
            onClick={handleRegister}
            disabled={isLoading}
            className="auth-button secondary"
          >
            {isLoading ? '🔄 Registering...' : '📝 Register with Passkey'}
          </button>
        </div>

        <div className="auth-features">
          <div className="feature">
            <span className="feature-icon">👆</span>
            <span>Touch ID</span>
          </div>
          <div className="feature">
            <span className="feature-icon">👤</span>
            <span>Face ID</span>
          </div>
          <div className="feature">
            <span className="feature-icon">🔑</span>
            <span>Security Key</span>
          </div>
        </div>

        <div className="auth-benefits">
          <h4>Why biometric authentication?</h4>
          <ul>
            <li>✅ No passwords to remember or forget</li>
            <li>✅ Secure access to your health data</li>
            <li>✅ One-touch login every time</li>
            <li>✅ Works on all your devices</li>
          </ul>
        </div>

        {process.env.NODE_ENV === 'development' && (
          <div className="dev-tools">
            <h4>Development Tools</h4>
            <p><strong>App ID:</strong> {appId}</p>
            <p><strong>Status:</strong> {isLoaded ? 'Ready' : 'Loading'}</p>
            <button 
              onClick={() => console.log('Passage instance:', passage)} 
              className="dev-button"
            >
              Debug Passage
            </button>
          </div>
        )}
      </div>
    </div>
  );
};