local payphonesById = {}
local payphonesByNumber = {}

--- Initializer to ensure each payphone has an internal identifier (ID).
--- Uses 'number' as the fallback ID if none is provided in config.
function InitializePayphones()
    if Config and Config.Payphones then
        for _, phone in ipairs(Config.Payphones) do
            if not phone.id and phone.number then
                phone.id = 'phone_' .. phone.number
            end
            payphonesById[phone.id] = phone
            payphonesByNumber[phone.number] = phone
        end
    end
end

InitializePayphones()

--- Returns payphone data by its unique ID.
---@param id string
---@return table|nil
function GetPayphoneById(id)
    return payphonesById[id]
end

--- Returns payphone data by its phone number.
---@param number string
---@return table|nil
function GetPayphoneByNumber(number)
    return payphonesByNumber[number]
end

--- Generates a unique voice channel based on the call index.
---@param callIndex number
---@return number
function GenerateVoiceChannel(callIndex)
    return Config.VoiceChannelBase + callIndex
end

--- Checks if two coordinates are within a specified distance.
---@param coords1 vector3
---@param coords2 vector3
---@param maxDist number
---@return boolean
function IsWithinDistance(coords1, coords2, maxDist)
    return #(coords1 - coords2) <= maxDist
end
