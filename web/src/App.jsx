import { useState, useEffect, useCallback } from 'react'
import { onNuiMessage, fetchNui, isEnvBrowser } from './utils/nui'
import AnalogPayphone from './components/AnalogPayphone'
import DigitalPayphone from './components/DigitalPayphone'
import './App.css'

function App() {
  const [visible, setVisible] = useState(false)
  const [theme, setTheme] = useState('analog') // 'analog' | 'digital'
  const [closing, setClosing] = useState(false)

  // Open the payphone UI
  useEffect(() => {
    return onNuiMessage('openPayphone', (data) => {
      setTheme(data.theme || 'analog')
      setClosing(false)
      setVisible(true)
    })
  }, [])

  // Close the payphone UI (from Lua)
  useEffect(() => {
    return onNuiMessage('closePayphone', () => {
      handleClose()
    })
  }, [])

  const handleClose = useCallback(() => {
    setClosing(true)
    setTimeout(() => {
      setVisible(false)
      setClosing(false)
    }, 350)
  }, [])

  const handleDial = useCallback((number) => {
    fetchNui('dial', { number })
    handleClose()
  }, [handleClose])

  const handleCancel = useCallback(() => {
    fetchNui('cancel')
    handleClose()
  }, [handleClose])

  // Dev mode: show UI for testing
  useEffect(() => {
    if (isEnvBrowser()) {
      const handler = (e) => {
        if (e.key === 'F2') {
          setTheme(prev => prev === 'analog' ? 'digital' : 'analog')
          setClosing(false)
          setVisible(true)
        }
        if (e.key === 'Escape' && visible) {
          handleCancel()
        }
      }
      window.addEventListener('keydown', handler)
      return () => window.removeEventListener('keydown', handler)
    }
  }, [visible, handleCancel])

  // Listen for Escape key in NUI
  useEffect(() => {
    if (!isEnvBrowser() && visible) {
      const handler = (e) => {
        if (e.key === 'Escape') {
          handleCancel()
        }
      }
      window.addEventListener('keydown', handler)
      return () => window.removeEventListener('keydown', handler)
    }
  }, [visible, handleCancel])

  if (!visible) return null

  const animClass = closing ? 'payphone-exit' : 'payphone-enter'

  return (
    <div className={`payphone-overlay ${animClass}`}>
      {theme === 'analog' ? (
        <AnalogPayphone onDial={handleDial} onCancel={handleCancel} />
      ) : (
        <DigitalPayphone onDial={handleDial} onCancel={handleCancel} />
      )}
    </div>
  )
}

export default App
