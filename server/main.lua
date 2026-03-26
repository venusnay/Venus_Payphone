--[[
    server/main.lua
    Ponto de entrada do server:
    - Callbacks de consulta de estado
    - Exports do resource para outros scripts
]]

-- ─────────────────────────────────────────────
--  EXPORTS PÚBLICOS
--  Outros resources podem consultar o estado dos payphones
-- ─────────────────────────────────────────────

--- Retorna o estado de um payphone por id.
---@param payphoneId string
---@return table|nil
exports('GetPayphoneState', function(payphoneId)
    return payphoneStates and payphoneStates[payphoneId] or nil
end)

--- Retorna todos os estados.
---@return table
exports('GetAllPayphoneStates', function()
    return payphoneStates or {}
end)

-- ─────────────────────────────────────────────
--  LOG DE INICIALIZAÇÃO
-- ─────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    print(string.format(
        '[PAYPHONES] Resource iniciado com %d orelhões configurados.',
        #Config.Payphones
    ))
end)
