import React, { useEffect } from 'react';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'passage-auth': any;
    }
  }
}

const LoginPage: React.FC = () => {
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

    // Check if already logged in
    script.onload = () => {
      console.log('✅ Passage script loaded in LoginPage');
      
      const checkAuth = async () => {
        try {
          console.log('🔍 LoginPage: Checking if already authenticated...');
          console.log('🌐 Window.Passage available in LoginPage:', !!window.Passage);
          
          // @ts-ignore - Passage will be available after script loads
          if (window.Passage) {
            const passage = new window.Passage(process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o');
            console.log('📦 Passage instance created in LoginPage:', passage);
            console.log('🔑 Using App ID in LoginPage:', process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o');
            
            const user = await passage.currentUser();
            console.log('👤 LoginPage currentUser result:', user);
            console.log('👤 LoginPage user type:', typeof user);
            console.log('👤 LoginPage user ID:', user?.id);
            console.log('👤 LoginPage user email:', user?.email);
            
            if (user && user.id) {
              console.log('✅ Already logged in, redirecting to dashboard from LoginPage');
              console.log('🔄 Redirecting to /dashboard...');
              window.location.href = '/dashboard';
            } else {
              console.log('ℹ️ No authenticated user found in LoginPage - showing login form');
            }
          }
        } catch (error) {
          console.error('🚨 LoginPage auth check failed:', error);
          console.error('🚨 LoginPage error type:', typeof error);
          console.error('🚨 LoginPage error message:', error.message);
          console.log('ℹ️ Not logged in, staying on login page');
        }
      };
      checkAuth();
    };
    
    script.onerror = () => {
      console.error('❌ Failed to load Passage script in LoginPage');
    };

    return () => {
      console.log('🧹 LoginPage cleanup');
      // Cleanup
      if (document.head.contains(script)) {
        document.head.removeChild(script);
      }
    };
  }, []);

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '2rem'
    }}>
      <div style={{
        background: 'white',
        padding: '3rem',
        borderRadius: '12px',
        boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
        width: '100%',
        maxWidth: '450px'
      }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ color: '#2d3748', margin: '0 0 0.5rem 0', fontSize: '2rem' }}>
            🌱 JLAM
          </h1>
          <p style={{ color: '#718096', margin: 0 }}>
            Veilige passwordless authenticatie
          </p>
        </div>

        {/* Passage Elements Authentication */}
        <div style={{ marginBottom: '2rem' }}>
          <passage-auth 
            app-id={process.env.REACT_APP_PASSAGE_APP_ID || 'HQ73ngumd21panzhrahe0k6o'}
            redirect-url={`${window.location.origin}/dashboard`}
          />
        </div>

        {/* Info over passwordless */}
        <div style={{ 
          background: '#f0f8ff', 
          padding: '1rem', 
          borderRadius: '8px',
          border: '1px solid #bee3f8',
          textAlign: 'center',
          marginBottom: '1.5rem'
        }}>
          <p style={{ margin: 0, fontSize: '0.9rem', color: '#2b6cb0' }}>
            🔒 <strong>Passwordless Authentication</strong><br/>
            Beveiligd met biometrische data en magic links
          </p>
        </div>

        {/* Features */}
        <div style={{ 
          display: 'grid', 
          gap: '0.75rem', 
          fontSize: '0.875rem',
          marginBottom: '1.5rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span>🔐</span>
            <span>Geen wachtwoorden nodig</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span>📱</span>
            <span>Biometrische authenticatie (Face ID, Touch ID)</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span>📧</span>
            <span>Veilige magic links via email</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span>⚡</span>
            <span>Sneller en veiliger dan traditionele login</span>
          </div>
        </div>

        {/* Info */}
        <div style={{
          padding: '1rem',
          background: '#f7fafc',
          borderRadius: '8px',
          border: '1px solid #e2e8f0',
          textAlign: 'center'
        }}>
          <p style={{ margin: 0, fontSize: '0.875rem', color: '#4a5568' }}>
            🛡️ Powered by Passage - Enterprise-grade security
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;