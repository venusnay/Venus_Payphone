--[[
    config.lua
    Main configuration for the payphones system.
    Edit this file to add/remove payphones and adjust behavior.
]]

Config = {}

-- ─────────────────────────────────────────────
--  FRAMEWORK
-- 'standalone' | 'qbx_core'
Config.Framework   = 'standalone'

-- 'lb-phone' | 'none'
Config.PhoneSystem = 'none'

-- ─────────────────────────────────────────────
--  GENERAL BEHAVIOR
-- ─────────────────────────────────────────────
Config.CallTimeout      = 30        -- Seconds before a call expires without answer
Config.HangupDistance   = 3.5       -- Max distance from payphone before hanging up
Config.Cooldown         = 10        -- Cooldown seconds after ending a call
Config.CallCost         = 0         -- Cost per call (0 = free)
Config.CallCostItem     = 'money'   -- Item/account used for charging (framework)

-- ─────────────────────────────────────────────
--  UI THEME
--  'analog'  → Classic payphone with physical buttons and CRT display
--  'digital' → Modern touchscreen payphone with glass UI
-- ─────────────────────────────────────────────
Config.PayphoneTheme    = 'analog'

-- ─────────────────────────────────────────────
--  PMA-VOICE
-- ─────────────────────────────────────────────
Config.VoiceChannelBase = 1000      -- Base channel for calls (incremented by unique ID)

-- ─────────────────────────────────────────────
--  SOUNDS
-- ─────────────────────────────────────────────
Config.Sounds = {
    -- Ringing sound emitted BY the payphone (audible to everyone nearby)
    -- Type: 'native' (GTA sounds) | 'custom' (MP3 in the sounds folder)
    RingtoneWorld = {
        type = 'custom',
        file = 'ringtone.mp3', -- Must be in sounds/ringtone.mp3
        vol  = 0.1,            -- Base volume
        dist = 30.0,           -- Max audible distance (3D radius)
    },

    -- Ringtone the player hears when receiving a call (in their "ear")
    RingtoneLocal = {
        type = 'native',
        name = 'Phone_Ring_Tone',
        ref  = 'Phone_SoundSet_Michael'
    },

    -- Dial tone ("tuunn tuunn") while waiting for answer
    WaitingTone   = {
        type = 'native',
        name = 'Remote_Ring',
        ref  = 'Phone_SoundSet_Default'
    },

    -- Busy line tone
    BusyTone      = {
        type = 'native',
        name = 'Remote_Dial_Tone',
        ref  = 'Phone_SoundSet_Default'
    },

    -- Beep upon established connection
    ConnectBeep   = {
        type = 'native',
        name = 'CALL_CONNECTED',
        ref  = 'Phone_SoundSet_Default'
    },

    -- Sound when ending a call
    Disconnect    = {
        type = 'native',
        name = 'CALL_ENDED',
        ref  = 'Phone_SoundSet_Default'
    },
}

-- ─────────────────────────────────────────────
--  LOGS & DEBUG
-- ─────────────────────────────────────────────
Config.Debug = false -- Enable debug tools (e.g. copy generic phone coords)

Config.Logs = {
    enabled = true,
    type    = 'both',     -- 'ox_lib' | 'webhook' | 'both'
    webhook = '',         -- Discord webhook URL
    color   = 16776960,   -- Yellow for discord embed
}

-- ─────────────────────────────────────────────
--  PAYPHONES
--  (id)        → unique identifier (optional, auto-generated from number)
--  number      → dialable number (string)
--  label       → name shown in phonebook
--  coords      → vector4(x, y, z, heading)
--  spawnObject → true = create object; false = use map object
--  model          → model hash (only used if spawnObject = true)
--  private        → if true, won't show in public phonebook
--  incomingOnly   → if true, can only receive calls (no outgoing)
-- ─────────────────────────────────────────────
-- ─────────────────────────────────────────────
--  GENERIC PAYPHONES (Map Objects)
--  These models will allow outgoing calls only.
--  They won't have a fixed number or appear in the phonebook.
-- ─────────────────────────────────────────────
Config.GenericModels = {
    `prop_phonebox_01b`,
    `prop_phonebox_01c`,
    `prop_phonebox_02`,
    `prop_phonebox_03`,
    `prop_phonebox_04`,
    `prop_phonebox_01a`,
    `p_phonebox_02_s`,
}

Config.Payphones = {
    {
        label       = 'South Boulevard Del Perro / Boulevard Del Perro',
        number      = '1001',
        coords      = vec4(-841.40, -125.69, 36.54, 26.36),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'San Andreas Avenue / Peaceful Street',
        number      = '1002',
        coords      = vec4(-278.01, -684.29, 33.72, 160.70),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Vespucci Boulevard',
        number      = '1003',
        coords      = vec4(140.18, -1033.16, 28.34, 162.11),
        spawnObject = false,
        private     = false,
    },
    {
    label       = 'Capital Boulevard',
        number      = '1004',
        coords      = vec4(289.36, -1280.12, 28.45, 270.00),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Bay City Avenue / Equality Way',
        number      = '1005',
        coords      = vec4(-1363.46, -797.09, 18.30, 140.78),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Boulevard Del Perro',
        number      = '1006',
        coords      = vec4(-1541.13, -466.67, 34.42, 32.42),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Dorset Drive',
        number      = '1007',
        coords      = vec4(-701.46, -371.57, 33.28, 248.55),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Hawick Avenue / Las Lagunas Boulevard',
        number      = '1008',
        coords      = vec4(-53.45, -94.17, 56.77, 339.95),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Bank of Los Santos',
        number      = '1009',
        coords      = vec4(253.154, 222.135, 106.331, 0),
        spawnObject = false,
        private     = true,
    },
    {
        label       = 'Elgin Avenue / Adam\'s Apple Boulevard',
        number      = '1010',
        coords      = vec4(18.16, -1102.61, 30.12, 340.00),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Vinewood Boulevard',
        number      = '1011',
        coords      = vec4(129.41, 245.35, 106.43, 339.72),
        spawnObject = false,
        private     = false,
    },
    {
        label       = 'Niland Avenue / Alhambra Drive',
        number      = '1012',
        coords      = vec4(1959.06, 3738.40, 31.38, 299.43),
        spawnObject = false,
        model       = 1281992692,
        private     = false,
    },
    {
        label       = 'San Andreas Avenue / Palomino Avenue',
        number      = '1013',
        coords      = vec4(-664.60, -670.83, 30.40, 0.35),
        spawnObject = false,
        model       = 1281992692,
        private     = false,
    },
}
