if Config.PhoneSystem == 'lb-phone' then
    PhoneBridge = {}

--- Creates a call from a payphone to a regular phone number.
---@param source number The player source using the payphone.
---@param payphoneId string The ID of the payphone being used.
---@param payphoneNumber string The phone number of the payphone.
---@param targetNumber string The target phone number to call.
---@return any callData|nil
function PhoneBridge.CreateCall(source, payphoneId, payphoneNumber, targetNumber)
    -- Creates a call that is not shown on the phone UI
    local callId = exports["lb-phone"]:CreateCall({
        phoneNumber = payphoneNumber,
        source      = source
    }, targetNumber, {
        requirePhone = false,
        hideNumber   = false -- Payphones typically show their number
    })

    if callId then
        return { callId = callId, type = 'external' }
    end

    return nil
end

--- Ends a call for a player.
---@param source number
function PhoneBridge.EndCall(source)
    exports["lb-phone"]:EndCall(source)
end

--- Checks if a player is in a call.
---@param source number
---@return boolean, number|nil, any|nil
function PhoneBridge.IsInCall(source)
    return exports["lb-phone"]:IsInCall(source)
end

return PhoneBridge
end
