--[[
    bridge/qbx_core/server.lua
    Server bridge for qbx_core.
    Uses official exports: https://docs.qbox.re/resources/qbx_core/exports/server
]]

if Config.Framework ~= 'qbx_core' then return end

Bridge = Bridge or {}

--- Returns the qbx_core player object.
---@param source number
---@return table|nil
function Bridge.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

--- Returns the player's citizen identifier.
---@param source number
---@return string
function Bridge.GetIdentifier(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return tostring(source) end
    return player.PlayerData.citizenid
end

--- Sends a notification to the player via ox_lib.
---@param source number
---@param message string
---@param ntype string
function Bridge.Notify(source, message, ntype)
    TriggerClientEvent('ox_lib:notify', source, {
        type        = ntype or 'inform',
        description = message,
    })
end

--- Removes cash from the player.
---@param source number
---@param amount number
---@return boolean
function Bridge.RemoveMoney(source, amount)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    return player.Functions.RemoveMoney('cash', amount, 'payphone-call')
end
