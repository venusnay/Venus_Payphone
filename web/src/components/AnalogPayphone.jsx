import { useState, useCallback, useRef, useEffect } from 'react'
import './AnalogPayphone.css'

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

export default function AnalogPayphone({ onDial, onCancel }) {
  const [number, setNumber] = useState('')
  const [lastPressed, setLastPressed] = useState(null)
  const [ripples, setRipples] = useState([])
  const displayRef = useRef(null)
  const rippleId = useRef(0)

  const playKeySound = useCallback(() => {
    // DTMF-like feedback sound (Web Audio API)
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'sine'
      osc.frequency.value = 440 + Math.random() * 200
      gain.gain.value = 0.08
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start()
      osc.stop(ctx.currentTime + 0.1)
    } catch (e) { /* ignore audio errors */ }
  }, [])

  const handlePress = useCallback((key) => {
    if (number.length >= MAX_DIGITS) return
    playKeySound()
    setNumber(prev => prev + key)
    setLastPressed(key)
    setTimeout(() => setLastPressed(null), 200)
  }, [number, playKeySound])

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

  const createRipple = useCallback((e, btnEl) => {
    const rect = btnEl.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const id = ++rippleId.current
    setRipples(prev => [...prev, { id, x, y }])
    setTimeout(() => {
      setRipples(prev => prev.filter(r => r.id !== id))
    }, 600)
  }, [])

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

  return (
    <div className="analog-payphone">
      {/* Metal body texture overlay */}
      <div className="analog-body-texture" />
      
      {/* Top label plate */}
      <div className="analog-label-plate">
        <div className="analog-label-screws">
          <span className="screw" />
          <span className="screw" />
        </div>
        <div className="analog-label-text">PAYPHONE</div>
        <div className="analog-label-sub">Insert coin or dial direct</div>
      </div>

      {/* Display area */}
      <div className="analog-display-housing">
        <div className="analog-display" ref={displayRef}>
          <div className="analog-display-scanline" />
          <div className="analog-display-content">
            <div className="analog-display-label">DIAL NUMBER</div>
            <div className="analog-display-number">
              {number ? (
                number.split('').map((digit, i) => (
                  <span
                    key={i}
                    className="analog-digit"
                    style={{ animationDelay: `${i * 0.03}s` }}
                  >
                    {digit}
                  </span>
                ))
              ) : (
                <span className="analog-display-placeholder">_ _ _ _</span>
              )}
              <span className="analog-cursor" />
            </div>
            <div className="analog-display-status">
              {number.length > 0
                ? `${number.length}/${MAX_DIGITS} digits`
                : 'READY'}
            </div>
          </div>
        </div>
      </div>

      {/* Keypad */}
      <div className="analog-keypad">
        {KEYS.map(({ label, sub }) => (
          <button
            key={label}
            className={`analog-key ${lastPressed === label ? 'pressed' : ''}`}
            onClick={(e) => {
              handlePress(label)
              createRipple(e, e.currentTarget)
            }}
          >
            <span className="analog-key-label">{label}</span>
            {sub && <span className="analog-key-sub">{sub}</span>}
            {ripples.filter(r => true).map(r => (
              <span
                key={r.id}
                className="key-ripple"
                style={{ left: r.x, top: r.y }}
              />
            ))}
          </button>
        ))}
      </div>

      {/* Action buttons */}
      <div className="analog-actions">
        <button
          className="analog-action-btn analog-action-cancel"
          onClick={onCancel}
          title="Cancel"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
          <span>CANCEL</span>
        </button>
        <button
          className="analog-action-btn analog-action-clear"
          onClick={handleClear}
          title="Clear"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <path d="M21 4H8l-7 8 7 8h13a2 2 0 002-2V6a2 2 0 00-2-2z" />
            <line x1="18" y1="9" x2="12" y2="15" /><line x1="12" y1="9" x2="18" y2="15" />
          </svg>
          <span>CLEAR</span>
        </button>
        <button
          className={`analog-action-btn analog-action-call ${number.length > 0 ? 'active' : ''}`}
          onClick={handleCall}
          disabled={number.length === 0}
          title="Call"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" />
          </svg>
          <span>CALL</span>
        </button>
      </div>

      {/* Coin slot decoration */}
      <div className="analog-coin-slot">
        <div className="coin-slot-inner" />
      </div>

      {/* Bottom plate */}
      <div className="analog-bottom-plate">
        <span className="analog-serial">SN: BYD-PPH-2026</span>
      </div>
    </div>
  )
}
