--[[
    client/nui.lua
    Bridge between the React NUI interface and the Lua client.
    Handles opening/closing the payphone UI and receiving callbacks.
]]

local NUIState = {
    visible    = false,
    payphoneId = nil,
    isGeneric  = false,
    entity     = nil,
}

-- ─────────────────────────────────────────────
--  OPEN / CLOSE NUI
-- ─────────────────────────────────────────────

--- Opens the payphone NUI interface.
---@param payphoneId string
---@param isGeneric boolean|nil
---@param entity number|nil
function OpenPayphoneNUI(payphoneId, isGeneric, entity)
    if NUIState.visible then return end

    NUIState.visible    = true
    NUIState.payphoneId = payphoneId
    NUIState.isGeneric  = isGeneric or false
    NUIState.entity     = entity

    -- Determine which theme to use from config
    local theme = Config.PayphoneTheme or 'analog'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPayphone',
        theme  = theme,
    })
end

--- Closes the payphone NUI interface.
function ClosePayphoneNUI()
    if not NUIState.visible then return end

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closePayphone',
    })

    NUIState.visible    = false
    NUIState.payphoneId = nil
    NUIState.isGeneric  = false
    NUIState.entity     = nil
end

-- ─────────────────────────────────────────────
--  NUI CALLBACKS
-- ─────────────────────────────────────────────

--- Player pressed CALL in the NUI.
RegisterNUICallback('dial', function(data, cb)
    cb('ok')

    local targetNumber = data.number
    if not targetNumber or targetNumber == '' then
        ClosePayphoneNUI()
        return
    end

    local payphoneId = NUIState.payphoneId
    local isGeneric  = NUIState.isGeneric
    local entity     = NUIState.entity

    -- Close NUI first
    ClosePayphoneNUI()

    -- Proceed with the call (same logic as the old OpenDialMenu, but after getting the number)
    if not payphoneId then return end

    -- Set call state
    CallState_SetDialing(payphoneId, entity)

    TriggerServerEvent('payphones:server:dial', {
        payphoneId    = payphoneId,
        targetNumber  = tostring(targetNumber),
        isGeneric     = isGeneric,
    })

    BridgeClient.Notify(locale('calling_notify'):format(targetNumber), 'inform')
    lib.showTextUI(locale('calling_textui'):format(targetNumber), { position = 'left-center', icon = 'phone' })
    PlayWaitingTone()
    StartCallAnimation(entity)
    StartDistanceCheck(payphoneId)
end)

--- Player pressed CANCEL in the NUI.
RegisterNUICallback('cancel', function(_, cb)
    cb('ok')
    ClosePayphoneNUI()
end)
