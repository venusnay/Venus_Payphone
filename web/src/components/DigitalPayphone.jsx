import { useState, useCallback, useEffect, useRef } from 'react'
import './DigitalPayphone.css'

const MAX_DIGITS = 10

const KEYS = [
  { label: '1', sub: '' },
  { label: '2', sub: 'ABC' },
  { label: '3', sub: 'DEF' },
  { label: '4', sub: 'GHI' },
  { label: '5', sub: 'JKL' },
  { label: '6', sub: 'MNO' },
  { label: '7', sub: 'PQRS' },
  { label: '8', sub: 'TUV' },
  { label: '9', sub: 'WXYZ' },
  { label: '*', sub: '' },
  { label: '0', sub: '+' },
  { label: '#', sub: '' },
]

export default function DigitalPayphone({ onDial, onCancel }) {
  const [number, setNumber] = useState('')
  const [lastPressed, setLastPressed] = useState(null)
  const [touchFeedback, setTouchFeedback] = useState({})
  const activeTouch = useRef(null)

  const playTouchSound = useCallback(() => {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'triangle'
      osc.frequency.value = 800 + Math.random() * 400
      gain.gain.value = 0.04
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.06)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start()
      osc.stop(ctx.currentTime + 0.06)
    } catch (e) { /* ignore */ }
  }, [])

  const handlePress = useCallback((key) => {
    if (number.length >= MAX_DIGITS) return
    playTouchSound()
    setNumber(prev => prev + key)
    setLastPressed(key)
    setTouchFeedback(prev => ({ ...prev, [key]: true }))
    setTimeout(() => {
      setLastPressed(null)
      setTouchFeedback(prev => ({ ...prev, [key]: false }))
    }, 200)
  }, [number, playTouchSound])

  const handleBackspace = useCallback(() => {
    setNumber(prev => prev.slice(0, -1))
  }, [])

  const handleClear = useCallback(() => {
    setNumber('')
  }, [])

  const handleCall = useCallback(() => {
    if (number.length === 0) return
    onDial(number)
  }, [number, onDial])

  // Keyboard support
  useEffect(() => {
    const handler = (e) => {
      if (e.key >= '0' && e.key <= '9') handlePress(e.key)
      else if (e.key === '*') handlePress('*')
      else if (e.key === '#') handlePress('#')
      else if (e.key === 'Backspace') handleBackspace()
      else if (e.key === 'Enter' && number.length > 0) handleCall()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [handlePress, handleBackspace, handleCall, number])

  // Get time for status bar
  const [time, setTime] = useState(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
  useEffect(() => {
    const interval = setInterval(() => {
      setTime(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
    }, 30000)
    return () => clearInterval(interval)
  }, [])

  return (
    <div className="digital-payphone">
      {/* Screen bezel */}
      <div className="digital-bezel">
        {/* Glass reflection */}
        <div className="digital-glass-reflection" />

        {/* Status bar */}
        <div className="digital-status-bar">
          <div className="digital-status-left">
            <span className="digital-signal">
              <span className="signal-bar" style={{ height: 4 }} />
              <span className="signal-bar" style={{ height: 7 }} />
              <span className="signal-bar" style={{ height: 10 }} />
              <span className="signal-bar dim" style={{ height: 13 }} />
            </span>
            <span className="digital-carrier">PAYPHONE</span>
          </div>
          <div className="digital-status-right">
            <span className="digital-time">{time}</span>
          </div>
        </div>

        {/* Header */}
        <div className="digital-header">
          <div className="digital-header-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
              <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" />
            </svg>
          </div>
          <div className="digital-header-text">
            <h2 className="digital-title">Make a Call</h2>
            <p className="digital-subtitle">Enter the number below</p>
          </div>
        </div>

        {/* Display */}
        <div className="digital-display">
          <div className="digital-number-display">
            {number ? (
              <span className="digital-number-text">
                {number.split('').map((digit, i) => (
                  <span
                    key={i}
                    className="digital-digit-char"
                    style={{ animationDelay: `${i * 0.02}s` }}
                  >
                    {digit}
                  </span>
                ))}
              </span>
            ) : (
              <span className="digital-placeholder">Enter number...</span>
            )}
          </div>
          {number.length > 0 && (
            <button className="digital-backspace" onClick={handleBackspace}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M21 4H8l-7 8 7 8h13a2 2 0 002-2V6a2 2 0 00-2-2z" />
                <line x1="18" y1="9" x2="12" y2="15" />
                <line x1="12" y1="9" x2="18" y2="15" />
              </svg>
            </button>
          )}
        </div>

        {/* Touchscreen Keypad */}
        <div className="digital-keypad">
          {KEYS.map(({ label, sub }) => (
            <button
              key={label}
              className={`digital-key ${touchFeedback[label] ? 'touched' : ''}`}
              onClick={() => handlePress(label)}
            >
              <span className="digital-key-label">{label}</span>
              {sub && <span className="digital-key-sub">{sub}</span>}
              <div className="digital-key-glow" />
            </button>
          ))}
        </div>

        {/* Touchscreen Action Buttons */}
        <div className="digital-actions">
          <button className="digital-action digital-action-cancel" onClick={onCancel}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
          <button
            className={`digital-action digital-action-call ${number.length > 0 ? 'active' : ''}`}
            onClick={handleCall}
            disabled={number.length === 0}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" />
            </svg>
            <span>CALL</span>
          </button>
        </div>

        {/* Bottom indicator */}
        <div className="digital-bottom-bar">
          <div className="digital-home-indicator" />
        </div>
      </div>
    </div>
  )
}
