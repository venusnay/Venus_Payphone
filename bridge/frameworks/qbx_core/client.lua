--[[
    bridge/qbx_core/client.lua
    client bridge for qbx_core.
    Uses official exports: https://docs.qbox.re/resources/qbx_core/exports/client
]]

if Config.Framework ~= 'qbx_core' then return end

BridgeClient = BridgeClient or {}

--- Envia notificação local via ox_lib.
---@param message string
---@param ntype string
function BridgeClient.Notify(message, ntype)
    lib.notify({
        type        = ntype or 'inform',
        description = message,
    })
end

--- Retorna o citizenid do jogador local.
---@return string
function BridgeClient.GetIdentifier()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData then return playerData.citizenid end
    return tostring(GetPlayerServerId(PlayerId()))
end
