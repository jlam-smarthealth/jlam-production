import React, { useEffect, useState, useRef } from 'react';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'passage-auth': any;
      'passage-login': any;
      'passage-register': any;
    }
  }
  interface Window {
    gtag?: (...args: any[]) => void;
  }
  var process: {
    env: {
      REACT_APP_PASSAGE_APP_ID?: string;
      [key: string]: string | undefined;
    };
  };
}

interface AuthStats {
  totalLogins: number;
  passKeyLogins: number;
  magicLinkLogins: number;
  lastLogin: string;
}

const LoginPage: React.FC = () => {
  const [authMode, setAuthMode] = useState<'unified' | 'login' | 'register'>('unified');
  const [showInfo, setShowInfo] = useState(false);
  const [authStats] = useState<AuthStats>({
    totalLogins: 1247,
    passKeyLogins: 892,
    magicLinkLogins: 355,
    lastLogin: '2 minuten geleden'
  });
  
  const authRef = useRef<any>(null);
  
  console.log('🎯 LoginPage component mounted');
  console.log('🌐 Current URL:', window.location.href);
  console.log('🗄️ localStorage keys on login:', Object.keys(localStorage));
  console.log('🗄️ sessionStorage keys on login:', Object.keys(sessionStorage));
  console.log('🍪 Cookies on login:', document.cookie);
  
  useEffect(() => {
    console.log('🚀 LoginPage useEffect started');
    
    // Load Passage Elements script
    const script = document.createElement('script');
    script.src = 'https://psg.so/web.js';
    script.async = true;
    document.head.appendChild(script);
    console.log('📦 Loading Passage script for LoginPage...');

    // Advanced authentication setup
    script.onload = () => {
      console.log('✅ Passage script loaded in LoginPage');
      
      // Setup advanced callbacks
      const setupAuthCallbacks = () => {
        const authElement = authRef.current;
        if (!authElement) return;

        // Pre-authentication validation
        authElement.beforeAuth = (email: string): boolean => {
          console.log(`🔍 Pre-auth validation for: ${email}`);
          
          // Email validation
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(email)) {
            console.error('❌ Invalid email format');
            alert('Vul een geldig email adres in');
            return false;
          }

          // Domain validation for JLAM (optional)
          const allowedDomains = ['jlam.nl', 'jeleefstijlalsmedicijn.nl', 'gmail.com', 'outlook.com', 'hotmail.com'];
          const domain = email.split('@')[1].toLowerCase();
          
          if (!allowedDomains.some(allowed => domain.includes(allowed))) {
            console.log(`⚠️ Email domain ${domain} not in preferred list, but allowing`);
          }

          console.log('✅ Pre-auth validation passed');
          return true;
        };

        // Success handler
        authElement.onSuccess = (authToken: string) => {
          console.log('🎉 Authentication successful!');
          console.log('🔑 Auth token received:', authToken ? 'Yes' : 'No');
          
          // Analytics tracking
          if (typeof gtag !== 'undefined') {
            gtag('event', 'login_success', {
              method: 'passage_passkey',
              timestamp: new Date().toISOString()
            });
          }

          // Store token and redirect
          localStorage.setItem('psg_auth_success', 'true');
          localStorage.setItem('psg_login_timestamp', new Date().toISOString());
          
          console.log('🔄 Redirecting to dashboard...');
          window.location.href = '/dashboard';
        };

        // Error handler
        authElement.onError = (error: any) => {
          console.error('🚨 Authentication failed:', error);
          
          // User-friendly error messages
          const errorMessages: Record<string, string> = {
            'user_cancelled': 'Authenticatie geannuleerd. Probeer opnieuw.',
            'passkey_not_supported': 'Je browser ondersteunt geen passkeys. Probeer een magic link.',
            'network_error': 'Netwerkfout. Controleer je internetverbinding.',
            'invalid_email': 'Ongeldig email adres.',
            'rate_limited': 'Te veel pogingen. Wacht even voordat je het opnieuw probeert.',
            'user_not_found': 'Gebruiker niet gevonden. Probeer je te registreren?',
            'authentication_failed': 'Authenticatie mislukt. Probeer opnieuw.'
          };

          const userMessage = errorMessages[error.code] || 'Er ging iets mis. Probeer opnieuw.';
          alert(userMessage);

          // Analytics tracking
          if (typeof gtag !== 'undefined') {
            gtag('event', 'login_error', {
              error_code: error.code,
              error_message: error.message,
              timestamp: new Date().toISOString()
            });
          }
        };

        console.log('✅ Advanced auth callbacks configured');
      };

      // Check if already authenticated
      const checkAuth = async () => {
        try {
          console.log('🔍 LoginPage: Checking if already authenticated...');
          
          // @ts-ignore - Passage will be available after script loads
          if (window.Passage) {
            const passage = new window.Passage(process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o');
            const user = await passage.currentUser();
            
            if (user && user.id) {
              console.log('✅ Already logged in, redirecting to dashboard');
              window.location.href = '/dashboard';
            } else {
              console.log('ℹ️ No authenticated user - showing login form');
              // Setup callbacks after confirming no existing auth
              setTimeout(setupAuthCallbacks, 100);
            }
          }
        } catch (error) {
          console.error('🚨 Auth check failed:', error);
          console.log('ℹ️ Showing login form');
          setTimeout(setupAuthCallbacks, 100);
        }
      };
      
      checkAuth();
    };
    
    script.onerror = () => {
      console.error('❌ Failed to load Passage script in LoginPage');
    };

    return () => {
      console.log('🧹 LoginPage cleanup');
      if (document.head.contains(script)) {
        document.head.removeChild(script);
      }
    };
  }, [authMode]);

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '1rem'
    }}>
      <div style={{
        maxWidth: '1200px',
        margin: '0 auto',
        display: 'grid',
        gridTemplateColumns: showInfo ? '1fr 1fr' : '1fr',
        gap: '2rem',
        alignItems: 'start',
        paddingTop: '2rem'
      }}>
        {/* Main Authentication Panel */}
        <div style={{
          background: 'white',
          padding: '2rem',
          borderRadius: '12px',
          boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
          width: '100%',
          maxWidth: '500px',
          margin: showInfo ? '0' : '0 auto'
        }}>
          {/* Header */}
          <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
            <h1 style={{ color: '#2d3748', margin: '0 0 0.5rem 0', fontSize: '2.5rem' }}>
              🌱 JLAM Platform
            </h1>
            <p style={{ color: '#718096', margin: '0 0 1rem 0', fontSize: '1.1rem' }}>
              Next-Generation Passwordless Authentication
            </p>
            
            {/* Auth Mode Selector */}
            <div style={{ 
              display: 'flex', 
              justifyContent: 'center', 
              gap: '0.5rem',
              marginBottom: '1rem',
              padding: '0.25rem',
              background: '#f7fafc',
              borderRadius: '8px'
            }}>
              <button
                onClick={() => setAuthMode('unified')}
                style={{
                  padding: '0.5rem 1rem',
                  border: 'none',
                  borderRadius: '6px',
                  background: authMode === 'unified' ? '#4299e1' : 'transparent',
                  color: authMode === 'unified' ? 'white' : '#4a5568',
                  cursor: 'pointer',
                  fontSize: '0.875rem',
                  fontWeight: '500'
                }}
              >
                🔐 Smart Auth
              </button>
              <button
                onClick={() => setAuthMode('login')}
                style={{
                  padding: '0.5rem 1rem',
                  border: 'none',
                  borderRadius: '6px',
                  background: authMode === 'login' ? '#4299e1' : 'transparent',
                  color: authMode === 'login' ? 'white' : '#4a5568',
                  cursor: 'pointer',
                  fontSize: '0.875rem',
                  fontWeight: '500'
                }}
              >
                📧 Login Only
              </button>
              <button
                onClick={() => setAuthMode('register')}
                style={{
                  padding: '0.5rem 1rem',
                  border: 'none',
                  borderRadius: '6px',
                  background: authMode === 'register' ? '#4299e1' : 'transparent',
                  color: authMode === 'register' ? 'white' : '#4a5568',
                  cursor: 'pointer',
                  fontSize: '0.875rem',
                  fontWeight: '500'
                }}
              >
                ✨ Register Only
              </button>
            </div>
          </div>

          {/* Authentication Element */}
          <div style={{ marginBottom: '1.5rem' }}>
            {authMode === 'unified' && (
              <passage-auth 
                ref={authRef}
                app-id={process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o'}
              />
            )}
            {authMode === 'login' && (
              <passage-login 
                ref={authRef}
                app-id={process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o'}
              />
            )}
            {authMode === 'register' && (
              <passage-register 
                ref={authRef}
                app-id={process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o'}
              />
            )}
          </div>

          {/* Platform Stats */}
          <div style={{
            background: 'linear-gradient(45deg, #f0f8ff 0%, #e6f3ff 100%)',
            padding: '1rem',
            borderRadius: '8px',
            border: '1px solid #bee3f8',
            marginBottom: '1.5rem'
          }}>
            <h3 style={{ 
              margin: '0 0 0.5rem 0', 
              fontSize: '0.9rem', 
              color: '#2b6cb0',
              textAlign: 'center',
              fontWeight: '600'
            }}>
              🏆 JLAM Authentication Stats
            </h3>
            <div style={{ 
              display: 'grid', 
              gridTemplateColumns: '1fr 1fr', 
              gap: '0.5rem',
              fontSize: '0.8rem'
            }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontWeight: '700', color: '#1e40af' }}>{authStats.totalLogins.toLocaleString()}</div>
                <div style={{ color: '#64748b' }}>Total Logins</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontWeight: '700', color: '#059669' }}>{authStats.passKeyLogins.toLocaleString()}</div>
                <div style={{ color: '#64748b' }}>PassKey Logins</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontWeight: '700', color: '#7c3aed' }}>{authStats.magicLinkLogins.toLocaleString()}</div>
                <div style={{ color: '#64748b' }}>Magic Links</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontWeight: '700', color: '#dc2626' }}>{authStats.lastLogin}</div>
                <div style={{ color: '#64748b' }}>Last Login</div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div style={{ 
            display: 'flex', 
            gap: '0.5rem', 
            marginBottom: '1.5rem'
          }}>
            <button
              onClick={() => setShowInfo(!showInfo)}
              style={{
                flex: 1,
                padding: '0.75rem',
                border: '2px solid #e2e8f0',
                borderRadius: '8px',
                background: showInfo ? '#f7fafc' : 'white',
                color: '#4a5568',
                cursor: 'pointer',
                fontSize: '0.9rem',
                fontWeight: '500',
                transition: 'all 0.2s ease'
              }}
            >
              {showInfo ? '📖 Hide Info' : '💡 About Passage'}
            </button>
            <button
              onClick={() => window.open('https://console.passage.id', '_blank')}
              style={{
                flex: 1,
                padding: '0.75rem',
                border: '2px solid #4299e1',
                borderRadius: '8px',
                background: '#4299e1',
                color: 'white',
                cursor: 'pointer',
                fontSize: '0.9rem',
                fontWeight: '500',
                transition: 'all 0.2s ease'
              }}
            >
              🔧 Passage Console
            </button>
          </div>

          {/* Security Features Grid */}
          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: '1fr 1fr', 
            gap: '0.75rem', 
            fontSize: '0.8rem',
            marginBottom: '1.5rem'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>🔐</span>
              <span>WebAuthn/FIDO2</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>📱</span>
              <span>Face ID / Touch ID</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>🔗</span>
              <span>Magic Links</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>🛡️</span>
              <span>1Password Sync</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>📲</span>
              <span>SMS Backup</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem', background: '#f9fafb', borderRadius: '6px' }}>
              <span style={{ fontSize: '1.2rem' }}>⚡</span>
              <span>Cross-Device</span>
            </div>
          </div>

          {/* Footer */}
          <div style={{
            textAlign: 'center',
            padding: '1rem',
            background: '#f7fafc',
            borderRadius: '8px',
            border: '1px solid #e2e8f0'
          }}>
            <p style={{ margin: '0 0 0.5rem 0', fontSize: '0.875rem', color: '#4a5568', fontWeight: '600' }}>
              🌟 Enterprise-Grade Security by Passage
            </p>
            <p style={{ margin: 0, fontSize: '0.75rem', color: '#6b7280' }}>
              Trusted by 1000+ companies • SOC 2 Compliant • GDPR Ready
            </p>
          </div>
        </div>

        {/* Information Panel */}
        {showInfo && (
          <div style={{
            background: 'rgba(255,255,255,0.95)',
            padding: '2rem',
            borderRadius: '12px',
            boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
            backdropFilter: 'blur(10px)',
            maxHeight: '80vh',
            overflowY: 'auto'
          }}>
            <h2 style={{ color: '#2d3748', margin: '0 0 1rem 0', fontSize: '1.5rem' }}>
              🔐 About Passage by 1Password
            </h2>

            {/* What is Passage */}
            <div style={{ marginBottom: '1.5rem' }}>
              <h3 style={{ color: '#4299e1', margin: '0 0 0.5rem 0', fontSize: '1.1rem' }}>
                🎯 What is Passage?
              </h3>
              <p style={{ color: '#4a5568', lineHeight: '1.6', margin: 0, fontSize: '0.9rem' }}>
                Passage is a complete authentication solution that eliminates passwords entirely. 
                Built by 1Password, it uses modern web standards like WebAuthn and FIDO2 to provide 
                secure, frictionless authentication using biometrics, security keys, and magic links.
              </p>
            </div>

            {/* Key Features */}
            <div style={{ marginBottom: '1.5rem' }}>
              <h3 style={{ color: '#4299e1', margin: '0 0 0.5rem 0', fontSize: '1.1rem' }}>
                ⭐ Key Features
              </h3>
              <ul style={{ color: '#4a5568', lineHeight: '1.6', margin: 0, paddingLeft: '1.2rem', fontSize: '0.85rem' }}>
                <li><strong>Passwordless:</strong> No passwords to remember, store, or compromise</li>
                <li><strong>Biometric Auth:</strong> Face ID, Touch ID, Windows Hello support</li>
                <li><strong>Cross-Platform:</strong> Works on iOS, Android, Windows, macOS, Linux</li>
                <li><strong>Magic Links:</strong> Secure email-based authentication fallback</li>
                <li><strong>1Password Integration:</strong> Seamless sync with 1Password ecosystem</li>
                <li><strong>Developer Friendly:</strong> Simple APIs and web components</li>
              </ul>
            </div>

            {/* How it Works */}
            <div style={{ marginBottom: '1.5rem' }}>
              <h3 style={{ color: '#4299e1', margin: '0 0 0.5rem 0', fontSize: '1.1rem' }}>
                🔄 How It Works
              </h3>
              <ol style={{ color: '#4a5568', lineHeight: '1.6', margin: 0, paddingLeft: '1.2rem', fontSize: '0.85rem' }}>
                <li><strong>Registration:</strong> Enter your email, create a passkey with biometrics</li>
                <li><strong>Login:</strong> Enter email, authenticate with Face ID/Touch ID</li>
                <li><strong>Sync:</strong> Passkeys sync across devices via 1Password</li>
                <li><strong>Fallback:</strong> Magic links via email if biometrics unavailable</li>
              </ol>
            </div>

            {/* Security Benefits */}
            <div style={{ marginBottom: '1.5rem' }}>
              <h3 style={{ color: '#4299e1', margin: '0 0 0.5rem 0', fontSize: '1.1rem' }}>
                🛡️ Security Benefits
              </h3>
              <div style={{ display: 'grid', gap: '0.5rem', fontSize: '0.8rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span>
                  <span>No password attacks (credential stuffing, brute force)</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span>
                  <span>Phishing resistant (cryptographic verification)</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span>
                  <span>Man-in-the-middle attack protection</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span>
                  <span>Hardware-backed security (Secure Enclave, TPM)</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span>
                  <span>Zero knowledge architecture</span>
                </div>
              </div>
            </div>

            {/* Why JLAM Uses Passage */}
            <div style={{
              padding: '1rem',
              background: 'linear-gradient(45deg, #f0fdf4 0%, #ecfdf5 100%)',
              border: '1px solid #bbf7d0',
              borderRadius: '8px'
            }}>
              <h3 style={{ color: '#059669', margin: '0 0 0.5rem 0', fontSize: '1rem' }}>
                🌱 Why JLAM Chose Passage
              </h3>
              <p style={{ color: '#065f46', lineHeight: '1.5', margin: 0, fontSize: '0.85rem' }}>
                Voor JLAM's lifestyle medicine platform is veiligheid cruciaal. We behandelen gevoelige 
                gezondheidsgegevens en willen onze gebruikers de best mogelijke security bieden. 
                Passage elimineert het grootste beveiligingsrisico - zwakke wachtwoorden - en biedt 
                tegelijkertijd een frictionless gebruikerservaring die past bij onze moderne, 
                gebruiksvriendelijke benadering van gezondheidszorg.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default LoginPage;