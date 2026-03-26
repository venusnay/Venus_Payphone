--[[
    client/animations.lua
    Gerencia animações do jogador ao usar o payphone.
]]

-- ─────────────────────────────────────────────
--  CONFIGURAÇÕES DE ANIMAÇÃO (Isolado e forçado para máximo RP)
-- ─────────────────────────────────────────────
local AnimSettings = {
    advDict     = 'anim@scripted@payphone_hits@male@',
    pedAnim     = 'fxfr_phl_1_intro_male',
    phoneAnim   = 'fxfr_pcn_1_intro_phone',
    outroAnim   = 'exit_left_male',
    flag        = 14 -- 14 impede movimento (2 - loop + 4 - lock last frame + 8 - upperbody)
}

local animPlaying = false
local currentPayphoneProp = nil
local hiddenPayphoneEntity = nil
local hasSwappedProp = false

-- Mapeamento Estático -> Animado (usado para saber QUAIS valem a pena trocar o modelo da parede)
local AnimatedModels = {
    [`prop_phonebox_01b`] = `sf_prop_sf_phonebox_01b_s`,
    [`prop_phonebox_01c`] = `sf_prop_sf_phonebox_01c_s`,
    [`prop_phonebox_02`]  = `p_phonebox_02_s`,
    [`p_phonebox_02_s`]   = `p_phonebox_02_s`,
    [`sf_prop_sf_phonebox_01b_s`] = `sf_prop_sf_phonebox_01b_s`,
}

-- Modelos comuns para achar a entidade caso não seja enviada pelo ox_target (zonas de esfera)
local AllPayphoneModels = {
    `prop_phonebox_01a`, `prop_phonebox_01b`, `prop_phonebox_01c`, 
    `prop_phonebox_02`, `prop_phonebox_03`, `prop_phonebox_04`,
    `p_phonebox_02_s`, `sf_prop_sf_phonebox_01b_s`, `m25_2_prop_m52_phonebox_01a`
}

--- Carrega um dicionário de animação de forma assíncrona com timeout.
---@param dict string
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 500
        while not HasAnimDictLoaded(dict) and timeout > 0 do Wait(10); timeout = timeout - 1 end
    end
end

--- Tenta encontrar a entidade do orelhão mais próxima
---@param pedCoords vector3
---@return number|nil
local function FindClosestPayphone(pedCoords)
    for _, model in ipairs(AllPayphoneModels) do
        local obj = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, 2.0, model, false, false, false)
        if obj and obj > 0 then return obj end
    end
    -- Tenta sem filtro se for prop customizado
    return GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, 2.0, 0, false, false, false)
end

--- Inicia a animação de chamada telefônica garantindo sempre o posicionamento perfeito.
---@param entity number|nil Entidade vinda do evento de target
function StartCallAnimation(entity)
    if animPlaying then return end
    local ped = PlayerPedId()

    -- Se não recebemos a entidade exata (ex: target area de raio), procuramos a mais próxima fisicamente
    if not entity or not DoesEntityExist(entity) then
        entity = FindClosestPayphone(GetEntityCoords(ped))
    end

    if not entity or not DoesEntityExist(entity) then return end -- Sem orelhão, sem animação

    LoadAnimDict(AnimSettings.advDict)

    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)

    -- 1. POSICIONAMENTO FORÇADO E PERFEITO DO JOGADOR SEMPRE
    local offset = GetOffsetFromEntityInWorldCoords(entity, -0.10, -0.85, 0.0)
    SetEntityCoords(ped, offset.x, offset.y, offset.z, false, false, false, false)
    SetEntityHeading(ped, heading)

    -- 2. TRATAMENTO DO PROP
    local originalModel = GetEntityModel(entity)
    local animatedPropHash = AnimatedModels[originalModel]

    if animatedPropHash then
        -- ORELHÃO COMPATÍVEL: Apaga o original e spawna o animado
        hasSwappedProp = true
        hiddenPayphoneEntity = entity
        SetEntityVisible(hiddenPayphoneEntity, false, false)
        
        currentPayphoneProp = CreateObjectNoOffset(animatedPropHash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(currentPayphoneProp, heading)
        SetEntityCompletelyDisableCollision(currentPayphoneProp, true, false)

        PlayEntityAnim(currentPayphoneProp, AnimSettings.phoneAnim, AnimSettings.advDict, 10.0, true, true, true, 0.0, 0)
    else
        -- ORELHÃO DE VIDRO/INCOMPATÍVEL: Não apaga a máquina, spawna APENAS um celular
        hasSwappedProp = false
        local handsetHash = `prop_npc_phone_02`
        if not HasModelLoaded(handsetHash) then RequestModel(handsetHash) end
        local timeout = 500
        while not HasModelLoaded(handsetHash) and timeout > 0 do Wait(10); timeout = timeout - 1 end
        
        if HasModelLoaded(handsetHash) then
            currentPayphoneProp = CreateObject(handsetHash, 0, 0, 0, true, true, false)
            SetModelAsNoLongerNeeded(handsetHash)
            -- Handset preso precisamente na mão
            AttachEntityToEntity(currentPayphoneProp, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        end
    end

    -- 3. INICIAR ANIMAÇÃO DO PED (Flag 14 proíbe de andar casualmente e prende na call)
    TaskPlayAnim(ped, AnimSettings.advDict, AnimSettings.pedAnim, 8.0, 8.0, -1, AnimSettings.flag, 0, false, false, false)
    
    animPlaying = true
end

--- Encerra a animação de chamada telefônica.
function StopCallAnimation()
    if not animPlaying then return end
    local ped = PlayerPedId()

    TaskPlayAnim(ped, AnimSettings.advDict, AnimSettings.outroAnim, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(2500)
    ClearPedTasks(ped)

    -- Limpeza do prop gerado (seja cabine animada ou celular solto)
    if currentPayphoneProp and DoesEntityExist(currentPayphoneProp) then
        DeleteEntity(currentPayphoneProp)
        currentPayphoneProp = nil
    end

    -- Devolve visibilidade a cabine original se foi apagada
    if hasSwappedProp and hiddenPayphoneEntity and DoesEntityExist(hiddenPayphoneEntity) then
        SetEntityVisible(hiddenPayphoneEntity, true, false)
        hiddenPayphoneEntity = nil
    end

    animPlaying = false
    hasSwappedProp = false
end

--- Retorna se uma animação está em execução.
---@return boolean
function IsAnimPlaying()
    return animPlaying
end
