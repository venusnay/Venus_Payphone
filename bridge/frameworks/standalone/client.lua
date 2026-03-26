--[[
    bridge/standalone/client.lua
    Bridge client standalone — sem framework externo.
]]

if Config.Framework ~= 'standalone' then return end

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

--- Retorna o identificador do jogador local.
---@return string
function BridgeClient.GetIdentifier()
    return GetPlayerIdentifierByType(PlayerId(), 'license') or tostring(GetPlayerServerId(PlayerId()))
end
