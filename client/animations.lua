--[[
    client/animations.lua
    Gerencia animações do jogador ao usar o payphone.
]]

local animPlaying = false

--- Carrega um dicionário de animação de forma assíncrona.
---@param dict string
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

--- Inicia a animação de chamada telefônica.
function StartCallAnimation()
    if animPlaying then return end
    local cfg  = Config.Animations
    LoadAnimDict(cfg.dict)
    local ped = PlayerPedId()
    TaskPlayAnim(ped, cfg.dict, cfg.anim, 8.0, -8.0, -1, cfg.flag, 0, false, false, false)
    animPlaying = true
end

--- Encerra a animação de chamada telefônica.
function StopCallAnimation()
    if not animPlaying then return end
    local ped = PlayerPedId()
    StopAnimTask(ped, Config.Animations.dict, Config.Animations.anim, 4.0)
    animPlaying = false
end

--- Retorna se uma animação está em execução.
---@return boolean
function IsAnimPlaying()
    return animPlaying
end
