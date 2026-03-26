--[[
    client/calls.lua
    Handles the call flow on the client side:
    - Dialing
    - Incoming calls
    - Accept / Reject
    - Hang up
    - pma-voice integration (setCallChannel)
]]

lib.locale()

-- Local call state
local CallState = {
    active         = false,
    incoming       = false,
    dialing        = false,
    payphoneId     = nil,
    voiceChannel   = nil,
    distanceThread = nil,
}

-- ─────────────────────────────────────────────
--  VOICE CHANNEL CONTROL (pma-voice)
-- ─────────────────────────────────────────────

--- Joins the specified voice channel.
---@param channel number
local function JoinVoiceChannel(channel)
    if not channel or type(channel) ~= 'number' then return end
    exports['pma-voice']:setCallChannel(channel)
    CallState.voiceChannel = channel
end

--- Leaves the current voice channel.
local function LeaveVoiceChannel()
    if CallState.voiceChannel then
        exports['pma-voice']:setCallChannel(0)
        CallState.voiceChannel = nil
    end
end

-- ─────────────────────────────────────────────
--  DISTANCE THREAD
--  Ends the call if the player moves too far away.
-- ─────────────────────────────────────────────

local function StartDistanceCheck(payphoneId)
    if CallState.distanceThread then return end

    local phone = GetPayphoneById(payphoneId)
    if not phone then return end

    local coords = vector3(phone.coords.x, phone.coords.y, phone.coords.z)

    CallState.distanceThread = CreateThread(function()
        while CallState.active or CallState.incoming or CallState.dialing do
            Wait(500)
            local pedCoords = GetEntityCoords(PlayerPedId())
            if #(pedCoords - coords) > Config.HangupDistance then
                -- Player moved too far — end call
                TriggerServerEvent('payphones:server:hangup', { payphoneId = payphoneId, reason = 'distance' })
                CleanupCallState()
                BridgeClient.Notify(locale('distance_limit_warning'), 'warning')
                break
            end
        end
        CallState.distanceThread = nil
    end)
end

-- ─────────────────────────────────────────────
--  STATE CLEANUP
-- ─────────────────────────────────────────────

function CleanupCallState()
    LeaveVoiceChannel()
    StopCallAnimation()
    StopRingtone()
    lib.hideTextUI()
    CallState.active       = false
    CallState.incoming     = false
    CallState.dialing      = false
    CallState.payphoneId   = nil
end

--- Returns the current payphone ID if the player is in a call.
_G.GetActiveCallPhoneId = function()
    return (CallState.active or CallState.dialing) and CallState.payphoneId or nil
end

--- Returns true if the player is currently in a call or dialing.
_G.IsPlayerInCall = function()
    return CallState.active or CallState.dialing
end

-- ─────────────────────────────────────────────
--  DIALING
-- ─────────────────────────────────────────────

--- Opens the dialing input and sends the request to the server.
---@param payphoneId string
---@param isGeneric boolean|nil
function OpenDialMenu(payphoneId, isGeneric)
    if CallState.active or CallState.incoming then
        BridgeClient.Notify(locale('already_in_call'), 'error')
        return
    end

    local input = lib.inputDialog(locale('dial_title'), {
        {
            type        = 'input',
            label       = locale('dial_input_label'),
            placeholder = locale('dial_placeholder'),
            required    = true,
            min         = 1,
            max         = 10,
        },
    })

    if not input or not input[1] or input[1] == '' then return end

    local targetNumber = tostring(input[1])
    CallState.payphoneId = payphoneId
    CallState.dialing    = true

    TriggerServerEvent('payphones:server:dial', {
        payphoneId    = payphoneId,
        targetNumber  = targetNumber,
        isGeneric     = isGeneric
    })

    BridgeClient.Notify(locale('calling_notify'):format(targetNumber), 'inform')
    lib.showTextUI(locale('calling_textui'):format(targetNumber), { position = 'left-center', icon = 'phone' })
    PlayWaitingTone()
    StartDistanceCheck(payphoneId)
end

-- ─────────────────────────────────────────────
--  INCOMING CALL
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:client:incomingCall', function(data)
    -- data: { callId, callerNumber, payphoneId }
end)

--- Answers a pending call on the payphone.
---@param payphoneId string
function AcceptIncomingCall(payphoneId)
    local stateData = GetLocalPayphoneState(payphoneId)
    if not stateData or not stateData.extra or not stateData.extra.callId then
        BridgeClient.Notify(locale('no_call_to_answer'), 'error')
        return
    end

    if CallState.active or CallState.incoming then
        BridgeClient.Notify(locale('already_in_call'), 'error')
        return
    end

    TriggerServerEvent('payphones:server:acceptCall', {
        callId = stateData.extra.callId,
        payphoneId = payphoneId
    })
end

--- Rejects a pending call on the payphone.
---@param payphoneId string
function RejectIncomingCall(payphoneId)
    local stateData = GetLocalPayphoneState(payphoneId)
    if not stateData or not stateData.extra or not stateData.extra.callId then
        return
    end

    TriggerServerEvent('payphones:server:rejectCall', {
        callId = stateData.extra.callId,
        reason = 'rejected'
    })
end

-- ─────────────────────────────────────────────
--  CALL CONNECTED (both sides)
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:client:callConnected', function(data)
    -- data: { voiceChannel, payphoneId }
    CallState.active     = true
    CallState.incoming   = false
    CallState.payphoneId = data.payphoneId

    StopRingtone() -- Ensure dialing/ringing sound stops
    JoinVoiceChannel(data.voiceChannel)
    StartCallAnimation()
    PlayConnectBeep()
    StartDistanceCheck(data.payphoneId)

    lib.showTextUI(locale('in_call_textui'), { position = 'left-center', icon = 'phone-volume' })
    BridgeClient.Notify(locale('call_connected_notify'), 'success')
end)

-- ─────────────────────────────────────────────
--  CALL ENDED (any reason)
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:client:callEnded', function(data)
    -- data: { reason }
    local messages = {
        hangup   = locale('call_ended_msg'),
        distance = locale('call_end_distance'),
        timeout  = locale('call_end_timeout'),
        rejected = locale('call_end_rejected'),
        busy     = locale('call_end_busy'),
        invalid  = locale('call_end_invalid'),
        error    = locale('call_end_error'),
    }

    local reason = (data and data.reason) or 'hangup'
    BridgeClient.Notify(messages[reason] or messages['hangup'], 'warning')

    PlayDisconnectSound()
    CleanupCallState()
end)

-- ─────────────────────────────────────────────
--  KEYBIND: HANG UP (END key)
-- ─────────────────────────────────────────────

lib.addKeybind({
    name        = 'payphone_hangup',
    description = 'Hang up payphone call',
    defaultKey  = 'END',
    onPressed   = function()
        if not CallState.active then return end
        TriggerServerEvent('payphones:server:hangup', {
            payphoneId = CallState.payphoneId,
            reason     = 'hangup',
        })
        PlayDisconnectSound()
        CleanupCallState()
        BridgeClient.Notify(locale('call_ended_msg'), 'inform')
    end,
})
