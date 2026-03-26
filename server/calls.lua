--[[
    server/calls.lua
    Server-side call management:
    - State for each payphone
    - Call routing
    - Automatic timeout
    - Logs
]]

lib.locale()

-- ─────────────────────────────────────────────
--  PAYPHONE STATES
--  payphoneStates[payphoneId] = {
--      status   = 'idle'|'ringing'|'in_call'|'busy',
--      occupant = source,
--  }
-- ─────────────────────────────────────────────
local payphoneStates = {}

-- Initialize all payphones as 'idle'
CreateThread(function()
    for _, phone in ipairs(Config.Payphones) do
        payphoneStates[phone.id] = { status = 'idle', occupant = nil }
    end
end)

-- ─────────────────────────────────────────────
--  ACTIVE CALLS
--  activeCalls[callId] = {
--      callerId       = source,
--      callerPhone    = payphoneId,
--      receiverId     = source,
--      receiverPhone  = payphoneId,
--      voiceChannel   = number,
--      timeoutTimer   = timer ref,
--  }
-- ─────────────────────────────────────────────
local activeCalls     = {}
local callIdCounter   = 0

--- Generates a unique call ID.
---@return string
local function NewCallId()
    callIdCounter = callIdCounter + 1
    return 'call_' .. callIdCounter
end

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────

--- Checks if the source is currently occupying any payphone.
---@param source number
---@return string|nil payphoneId
local function GetOccupiedPayphone(source)
    for id, state in pairs(payphoneStates) do
        if state.occupant == source then
            return id
        end
    end
    return nil
end

--- Returns the callId where the source is participating.
---@param source number
---@return string|nil, table|nil
local function GetCallBySource(source)
    for id, call in pairs(activeCalls) do
        if call.callerId == source or call.receiverId == source then
            return id, call
        end
    end
    return nil, nil
end

--- Sets a payphone's status and notifies all clients.
---@param payphoneId string
---@param status string
---@param occupant number|nil
---@param extra table|nil
local function SetPayphoneStatus(payphoneId, status, occupant, extra)
    payphoneStates[payphoneId] = { status = status, occupant = occupant, extra = extra }
    TriggerClientEvent('payphones:client:stateUpdate', -1, { payphoneId = payphoneId, status = status, extra = extra })
end

-- Sync states when a player joins
RegisterNetEvent('payphones:server:syncStates', function()
    local source = source
    for id, state in pairs(payphoneStates) do
        if state.status ~= 'idle' then
            TriggerClientEvent('payphones:client:stateUpdate', source, { payphoneId = id, status = state.status, extra = state.extra })
        end
    end
end)

--- Destroys world ringtone for a payphone via xsound server-side (reaches all clients).
---@param payphoneId string
local function DestroyWorldRingtone(payphoneId)
    local soundId = 'payphone_world_' .. payphoneId
    if SoundBridge then
        SoundBridge.Stop(soundId)
    end
end

--- Plays world ringtone for a payphone via xsound server-side (reaches all clients).
---@param phone table
local function PlayWorldRingtone(phone)
    local s = Config.Sounds.RingtoneWorld
    if s and s.type == 'custom' then
        local soundId = 'payphone_world_' .. phone.id
        local coords = vector3(phone.coords.x, phone.coords.y, phone.coords.z)
        if SoundBridge then
            SoundBridge.Play('world', soundId, s.file, { loop = true, vol = s.vol or 0.5, coords = coords, dist = s.dist or 30.0 })
        end
    end
end

--- Ends and cleans up an active call.
---@param callId string
---@param reason string
local function EndCall(callId, reason)
    local call = activeCalls[callId]
    if not call then return end

    -- Immediately remove to prevent recursion loops (e.g. from lb-phone events)
    activeCalls[callId] = nil

    -- Cancel pending timeout
    if call.timeoutTimer then
        ClearTimeout(call.timeoutTimer)
        call.timeoutTimer = nil
    end

    -- Force destroy world ringtone via xsound server-side for ALL clients
    if call.receiverPhone then
        DestroyWorldRingtone(call.receiverPhone)
    end

    -- Notify both sides
    if call.callerId and call.callerId > 0 then
        TriggerClientEvent('payphones:client:callEnded', call.callerId, { reason = reason })
        TriggerClientEvent('payphones:client:applyCooldown', call.callerId, call.callerPhone)
    end

    if call.receiverId and call.receiverId > 0 then
        TriggerClientEvent('payphones:client:callEnded', call.receiverId, { reason = reason })
        TriggerClientEvent('payphones:client:applyCooldown', call.receiverId, call.receiverPhone)
    end

    -- Release payphones
    if call.callerPhone and not call.isGeneric then
        SetPayphoneStatus(call.callerPhone, 'idle', nil)
    end
    if call.receiverPhone then
        SetPayphoneStatus(call.receiverPhone, 'idle', nil)
    end

    -- External phone system integration
    if call.isExternal then
        PhoneBridge.EndCall(call.callerId)
    end

    -- Log call end
    LogCallEnd(callId, call.callerId, call.receiverId or 'N/A', reason)
end

-- ─────────────────────────────────────────────
--  EVENT: DIAL
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:server:dial', function(data)
    local source = source
    -- data: { payphoneId, targetNumber, isGeneric }

    -- Basic validation
    if not data or not data.payphoneId or not data.targetNumber then return end

    local callerPhone = GetPayphoneById(data.payphoneId)
    local callerNumber = 'Unknown'

    if not data.isGeneric then
        if not callerPhone then
            Bridge.Notify(source, locale('invalid_payphone'), 'error')
            return
        end
        callerNumber = callerPhone.number
    else
        -- Logic for generic phones (no fixed ID/number)
        callerNumber = locale('use_payphone_outgoing')
    end

    -- Ensure source is valid
    if source <= 0 then return end

    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)

    -- Distance check (if not generic)
    if not data.isGeneric and callerPhone then
        local phoneCoords = vector3(callerPhone.coords.x, callerPhone.coords.y, callerPhone.coords.z)
        if not IsWithinDistance(pCoords, phoneCoords, 5.0) then
            print(('[PAYPHONES] Possible exploit: player %s tried to dial from distance'):format(source))
            return
        end
    end

    -- Check if player is already in a call
    local existingCall = GetCallBySource(source)
    if existingCall then
        Bridge.Notify(source, locale('already_in_call'), 'error')
        return
    end

    -- Check origin payphone state (if not generic)
    if not data.isGeneric then
        local callerState = payphoneStates[data.payphoneId]
        if not callerState or callerState.status ~= 'idle' then
            Bridge.Notify(source, locale('number_busy'), 'error')
            return
        end
    end

    -- Locate target payphone
    local targetPhone = GetPayphoneByNumber(data.targetNumber)
    if not targetPhone then
        -- TRY EXTERNAL PHONE BRIDGE
        local externalCall = PhoneBridge.CreateCall(source, data.payphoneId, callerNumber, data.targetNumber)
        if externalCall then
            local callId = NewCallId()
            activeCalls[callId] = {
                callerId     = source,
                callerPhone  = data.payphoneId,
                callerNumber = callerNumber,
                isGeneric    = data.isGeneric,
                isExternal   = true,
                externalData = externalCall,
                voiceChannel = nil -- Handle by phone bridge
            }
            if not data.isGeneric then
                SetPayphoneStatus(data.payphoneId, 'busy', source)
            end
            TriggerClientEvent('payphones:client:dialing', source, { targetNumber = data.targetNumber, payphoneId = data.payphoneId })
            return
        end

        Bridge.Notify(source, locale('call_end_invalid'), 'error')
        TriggerClientEvent('payphones:client:callEnded', source, { reason = 'invalid' })
        return
    end

    -- Prevent calling self
    if not data.isGeneric and targetPhone.id == data.payphoneId then
        Bridge.Notify(source, locale('incorrect_payphone'), 'error')
        TriggerClientEvent('payphones:client:callEnded', source, { reason = 'error' })
        return
    end

    -- Check target payphone state
    local targetState = payphoneStates[targetPhone.id]
    if not targetState or targetState.status ~= 'idle' then
        Bridge.Notify(source, locale('call_end_busy'), 'warning')
        TriggerClientEvent('payphones:client:callEnded', source, { reason = 'busy' })
        return
    end

    -- Start the call
    local callId      = NewCallId()
    local channel     = GenerateVoiceChannel(callIdCounter)

    -- Reserve payphones
    if not data.isGeneric then
        SetPayphoneStatus(data.payphoneId, 'busy', source)
    end

    SetPayphoneStatus(targetPhone.id,  'ringing', nil, {
        callId       = callId,
        callerNumber = callerNumber,
    })

    PlayWorldRingtone(targetPhone)

    activeCalls[callId] = {
        callerId      = source,
        callerPhone   = data.payphoneId,
        callerNumber  = callerNumber,
        isGeneric     = data.isGeneric,
        receiverId    = nil,                   -- filled upon acceptance
        receiverPhone = targetPhone.id,
        voiceChannel  = channel,
        timeoutTimer  = nil,
    }

    -- Notify nearby players of the target payphone
    TriggerClientEvent('payphones:client:incomingCall', -1, {
        callId       = callId,
        callerNumber = callerNumber,
        payphoneId   = targetPhone.id,
    })

    -- Log
    if Config.Logs and Config.Logs.enabled then
        print(string.format(
            '[PAYPHONES] Call started %s | From: %s (%s) → To: %s',
            callId, source, (callerPhone and callerPhone.number or 'Generic'), (targetPhone and targetPhone.number or 'Unknown')
        ))
    end

    -- Automatic Timeout (flag-based to guarantee cancellation)
    local timeoutMs = Config.CallTimeout * 1000
    activeCalls[callId].timeoutCancelled = false
    SetTimeout(timeoutMs, function()
        if activeCalls[callId] and not activeCalls[callId].timeoutCancelled then
            EndCall(callId, 'timeout')
        end
    end)
end)

-- ─────────────────────────────────────────────
--  EVENT: ACCEPT CALL
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:server:acceptCall', function(data)
    local source = source
    -- data: { callId, payphoneId }

    if not data or not data.callId then return end

    local call = activeCalls[data.callId]
    if not call then
        Bridge.Notify(source, locale('call_not_found'), 'error')
        return
    end

    -- Validate receiver payphone
    if data.payphoneId ~= call.receiverPhone then
        Bridge.Notify(source, locale('incorrect_payphone'), 'error')
        return
    end

    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local targetPhone = GetPayphoneById(call.receiverPhone)
    if targetPhone then
        local phoneCoords = vector3(targetPhone.coords.x, targetPhone.coords.y, targetPhone.coords.z)
        if not IsWithinDistance(pCoords, phoneCoords, 5.0) then
            print(('[PAYPHONES] Possible exploit: player %s tried to answer from distance'):format(source))
            return
        end
    end

    -- Check if target is still ringing
    if payphoneStates[call.receiverPhone].status ~= 'ringing' then
        Bridge.Notify(source, locale('call_no_longer_available'), 'warning')
        return
    end

    -- Cancel timeout via flag
    call.timeoutCancelled = true

    -- Force destroy world ringtone via xsound server-side for ALL clients
    DestroyWorldRingtone(call.receiverPhone)

    -- Register receiver
    activeCalls[data.callId].receiverId = source

    -- Update states
    SetPayphoneStatus(call.receiverPhone, 'in_call', source)
    if not call.isGeneric then
        SetPayphoneStatus(call.callerPhone,   'in_call', call.callerId)
    end

    -- Connect both parties to voice channel
    local connData = { voiceChannel = call.voiceChannel, payphoneId = nil }

    connData.payphoneId = call.callerPhone
    TriggerClientEvent('payphones:client:callConnected', call.callerId,  connData)

    connData.payphoneId = call.receiverPhone
    TriggerClientEvent('payphones:client:callConnected', source, connData)

    -- Charge player (if configured)
    if Config.CallCost > 0 then
        local success = Bridge.RemoveMoney(call.callerId, Config.CallCost)
        if not success then
            EndCall(data.callId, 'error')
            Bridge.Notify(call.callerId, locale('insufficient_balance'), 'error')
            return
        end
    end

    if Config.Logs and Config.Logs.enabled then
        print(string.format(
            '[PAYPHONES] Call %s accepted by source %s | Channel: %d',
            data.callId, source, call.voiceChannel
        ))
    end
end)

-- ─────────────────────────────────────────────
--  EVENT: REJECT CALL
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:server:rejectCall', function(data)
    -- data: { callId, reason }
    if not data or not data.callId then return end
    if activeCalls[data.callId] then
        EndCall(data.callId, data.reason or 'rejected')
    end
end)

-- ─────────────────────────────────────────────
--  EVENT: HANG UP
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:server:hangup', function(data)
    local source = source
    -- data: { payphoneId, reason }

    local callId, _ = GetCallBySource(source)
    if callId then
        EndCall(callId, (data and data.reason) or 'hangup')
    end
end)

-- ─────────────────────────────────────────────
--  CLEANUP: PLAYER DROPPED
-- ─────────────────────────────────────────────

-- ─────────────────────────────────────────────
--  PHONE SYSTEM INTEGRATION (LB-PHONE EVENTS)
-- ─────────────────────────────────────────────

if Config.PhoneSystem == 'lb-phone' then
    AddEventHandler("lb-phone:callAnswered", function(call)
        for id, pCall in pairs(activeCalls) do
            if pCall.isExternal and pCall.externalData and pCall.externalData.callId == call.callId then
                -- Notify payphone user that call is connected
                TriggerClientEvent('payphones:client:callConnected', pCall.callerId, {
                    voiceChannel = nil, -- Handled by lb-phone
                    payphoneId   = pCall.callerPhone
                })
                break
            end
        end
    end)

    AddEventHandler("lb-phone:callEnded", function(call)
        for id, pCall in pairs(activeCalls) do
            if pCall.isExternal and pCall.externalData and pCall.externalData.callId == call.callId then
                EndCall(id, 'hangup')
                break
            end
        end
    end)
end

AddEventHandler('playerDropped', function(reason)
    local source = source
    local callId, _ = GetCallBySource(source)
    if callId then
        EndCall(callId, 'hangup')
    end

    -- Release payphone if still reserved
    for id, state in pairs(payphoneStates) do
        if state.occupant == source then
            SetPayphoneStatus(id, 'idle', nil)
        end
    end
end)

-- ─────────────────────────────────────────────
--  CLEANUP: RESOURCE STOPPING
-- ─────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for callId, _ in pairs(activeCalls) do
        EndCall(callId, 'hangup')
    end
end)
