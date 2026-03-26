--[[
    bridge/standalone/server.lua
    Server bridge for standalone version — no external framework.
]]

if Config.Framework ~= 'standalone' then return end

Bridge = Bridge or {}

--- Returns basic player data.
---@param source number
---@return table|nil
function Bridge.GetPlayer(source)
    if not source or source <= 0 then return nil end
    return { source = source }
end

--- Returns the player's unique identifier.
---@param source number
---@return string
function Bridge.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license') or tostring(source)
end

--- Sends a notification to the player via ox_lib in standalone mode.
---@param source number
---@param message string
---@param ntype string  'success'|'error'|'inform'|'warning'
function Bridge.Notify(source, message, ntype)
    TriggerClientEvent('ox_lib:notify', source, {
        type        = ntype or 'inform',
        description = message,
    })
end

--- Removes money/items from the player (noop in standalone).
---@param source number
---@param amount number
---@return boolean
function Bridge.RemoveMoney(source, amount)
    return true
end
