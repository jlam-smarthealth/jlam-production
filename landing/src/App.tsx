import React, { useEffect, useState } from 'react'
import Hero from './components/Hero'
import Announcement from './components/Announcement'
import TechStack from './components/TechStack'
import Architecture from './components/Architecture'
import EuropeanHosting from './components/EuropeanHosting'
import Security from './components/Security'
import Footer from './components/Footer'
import { PassageAuthFixed } from './components/PassageAuthFixed'
import './App.css'

const App: React.FC = () => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [showAuth, setShowAuth] = useState(false)

  useEffect(() => {
    setIsLoaded(true)
  }, [])

  // Test authentication by showing auth component
  const handleTestAuth = () => {
    setShowAuth(true)
  }

  const handleAuthSuccess = (user: any) => {
    console.log('🎉 Authentication successful:', user)
    // In production, this would redirect to the app
    alert(`Welcome ${user.email || user.id}! Authentication successful.`)
  }

  const handleAuthError = (error: any) => {
    console.error('❌ Authentication failed:', error)
    alert(`Authentication failed: ${error.message || 'Unknown error'}`)
  }

  if (showAuth) {
    return (
      <div className={`app ${isLoaded ? 'loaded' : ''}`}>
        <div style={{ padding: '2rem', maxWidth: '600px', margin: '0 auto' }}>
          <button 
            onClick={() => setShowAuth(false)}
            style={{ marginBottom: '2rem', padding: '0.5rem 1rem', cursor: 'pointer' }}
          >
            ← Back to Landing Page
          </button>
          <PassageAuthFixed 
            appId="HQ73ngumd21panzhrahe0k6o"
            onAuthSuccess={handleAuthSuccess}
            onAuthError={handleAuthError}
          />
        </div>
      </div>
    )
  }

  return (
    <div className={`app ${isLoaded ? 'loaded' : ''}`}>
      <Hero />
      <Announcement />
      
      {/* Test Authentication Button */}
      <div style={{ textAlign: 'center', padding: '2rem', background: '#f0f8ff' }}>
        <h2>🧪 Test Biometric Authentication</h2>
        <p>Click below to test the enhanced Passage biometric authentication with Authentikit</p>
        <button 
          onClick={handleTestAuth}
          style={{
            background: 'linear-gradient(135deg, #3182ce, #805ad5)',
            color: 'white',
            border: 'none',
            padding: '1rem 2rem',
            borderRadius: '8px',
            fontSize: '1.1rem',
            fontWeight: 'bold',
            cursor: 'pointer',
            marginTop: '1rem'
          }}
        >
          🔐 Test Biometric Login
        </button>
      </div>

      <TechStack />
      <Architecture />
      <EuropeanHosting />
      <Security />
      <Footer />
    </div>
  )
}

export default App