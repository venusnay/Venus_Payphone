--[[
    client/sounds.lua
    Manages payphone sounds (ringtone, busy, etc.)
    Uses bridge for custom sounds (xsound) or native GTA V sounds.
]]

local ringSoundId  = -1
-- Table to track active world sounds by payphoneId
local activeRings = {}

--- Returns true if a ringtone is currently playing for the given payphone.
---@param payphoneId string
---@return boolean
function IsRingtoneActive(payphoneId)
    return activeRings[payphoneId] ~= nil
end

--- Loads all audio banks configured in Config.Sounds (native only).
function LoadAudioBanks()
    if not Config or not Config.Sounds then return end

    local requested = {}
    for _, soundData in pairs(Config.Sounds) do
        if soundData.type == 'native' and soundData.ref and not requested[soundData.ref] then
            RequestScriptAudioBank(soundData.ref, false)
            requested[soundData.ref] = true
        end
    end
end

--- Starts the incoming call ringtone on the local player.
function PlayRingtone()
    LoadAudioBanks()
    StopRingtone()

    local s = Config.Sounds.RingtoneLocal
    if s.type == 'custom' then
        SoundBridge.Play('local', 'payphone_local', s.file, { loop = true, vol = s.vol or 1.0 })
    else
        ringSoundId = GetSoundId()
        PlaySoundFromEntity(ringSoundId, s.name, PlayerPedId(), s.ref, false, 0)
    end
end

--- Plays the waiting tone (dial tone) on the local player.
function PlayWaitingTone()
    LoadAudioBanks()
    StopRingtone()

    local s = Config.Sounds.WaitingTone
    if s.type == 'custom' then
        SoundBridge.Play('local', 'payphone_local', s.file, { loop = true, vol = s.vol or 1.0 })
    else
        ringSoundId = GetSoundId()
        PlaySoundFrontend(ringSoundId, s.name, s.ref, true)
    end
end

--- Stops the local ringtone or waiting tone.
function StopRingtone()
    local s_local = Config.Sounds.RingtoneLocal
    local s_wait  = Config.Sounds.WaitingTone

    if s_local.type == 'custom' or s_wait.type == 'custom' then
        SoundBridge.Stop('payphone_local')
    end

    if ringSoundId ~= -1 then
        StopSound(ringSoundId)
        ReleaseSoundId(ringSoundId)
        ringSoundId = -1
    end
end

--- Plays the world ringtone at an entity or coordinates.
---@param payphoneId string
---@param entity number|nil
---@param coords vector3
function PlayRingtoneAtEntityOrCoords(payphoneId, entity, coords)
    if activeRings[payphoneId] then return end

    LoadAudioBanks()
    local s = Config.Sounds.RingtoneWorld
    local soundId = 'payphone_world_' .. payphoneId

    if s.type == 'custom' then
        SoundBridge.Play('world', soundId, s.file, { loop = true, vol = s.vol or 0.5, coords = coords, dist = s.dist or 30.0 })
        activeRings[payphoneId] = 'custom'
    else
        local id = GetSoundId()
        if entity and DoesEntityExist(entity) then
            -- Play attached to the payphone object
            PlaySoundFromEntity(id, s.name, entity, s.ref, false, 0)
        else
            -- Play at coordinates if object doesn't exist/far away
            PlaySoundFromCoord(id, s.name, coords.x, coords.y, coords.z, s.ref, false, s.dist or 30.0, 0)
        end
        activeRings[payphoneId] = id
    end
end

--- Stops the world ringtone playing at specific coordinates.
---@param payphoneId string
function StopRingtoneAtCoords(payphoneId)
    if activeRings[payphoneId] then
        if activeRings[payphoneId] == 'custom' then
            SoundBridge.Stop('payphone_world_' .. payphoneId)
        else
            StopSound(activeRings[payphoneId])
            ReleaseSoundId(activeRings[payphoneId])
        end
        activeRings[payphoneId] = nil
    end
end

--- Plays the busy tone briefly.
function PlayBusyTone()
    local s = Config.Sounds.BusyTone
    if s.type == 'custom' then
        SoundBridge.Play('local', 'payphone_temp', s.file, { vol = s.vol or 1.0 })
        SetTimeout(2000, function() SoundBridge.Stop('payphone_temp') end)
    else
        local id = GetSoundId()
        PlaySoundFrontend(id, s.name, s.ref, true)
        SetTimeout(2000, function() StopSound(id) ReleaseSoundId(id) end)
    end
end

--- Plays a confirmation beep (connection established).
function PlayConnectBeep()
    local s = Config.Sounds.ConnectBeep
    if s.type == 'custom' then
        SoundBridge.Play('local', 'payphone_temp', s.file, { vol = s.vol or 1.0 })
    else
        local id = GetSoundId()
        PlaySoundFrontend(id, s.name, s.ref, true)
        SetTimeout(1000, function() StopSound(id) ReleaseSoundId(id) end)
    end
end

--- Plays the disconnect/hangup sound.
function PlayDisconnectSound()
    local s = Config.Sounds.Disconnect
    if s.type == 'custom' then
        SoundBridge.Play('local', 'payphone_temp', s.file, { vol = s.vol or 1.0 })
    else
        local id = GetSoundId()
        PlaySoundFrontend(id, s.name, s.ref, true)
        SetTimeout(1000, function() StopSound(id) ReleaseSoundId(id) end)
    end
end
