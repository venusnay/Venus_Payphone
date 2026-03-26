--- Sound Bridge to xSound
SoundBridge = {}

--- Toca áudio MP3 (Customizado).
---@param type string 'local' ou 'world'
---@param id string ID único do som (ex: payphoneId)
---@param file string Nome do arquivo (ou URL se suportar)
---@param options table { loop: bool, vol: number, coords: vector3 }
function SoundBridge.Play(type, id, file, options)
    local xSound = exports.xsound
    if not xSound then return end

    -- Para carregar o som da pasta local sounds/, o xsound geralmente prefixa o caminho ou o FiveM o serve.
    local url = ('https://cfx-nui-%s/sounds/%s'):format(GetCurrentResourceName(), file)

    if type == 'world' and options.coords then
        -- Tocar em 3D
        if IsDuplicityVersion() then
            pcall(function()
                xSound:PlayUrlPos(-1, id, url, options.vol or 0.5, options.coords, options.loop or false)
                xSound:Distance(-1, id, options.dist or 30.0)
            end)
        else
            xSound:PlayUrlPos(id, url, options.vol or 0.5, options.coords, options.loop or false)
            xSound:Distance(id, options.dist or 30.0)
        end
    else
        -- Tocar em 2D (no ouvido do player)
        if not IsDuplicityVersion() then
            xSound:PlayUrl(id, url, options.vol or 0.5, options.loop or false)
        end
    end
end

--- Para um áudio.
---@param id string
function SoundBridge.Stop(id)
    local xSound = exports.xsound
    if not xSound then return end

    if IsDuplicityVersion() then
        pcall(function() xSound:Destroy(-1, id) end)
    else
        if xSound:soundExists(id) then
            xSound:Destroy(id)
        end
    end
end

--- Atualiza o volume de um som (se o xsound já não lidar com distância).
---@param id string
---@param volume number
function SoundBridge.UpdateVolume(id, volume)
    -- O xSound:PlayUrlPos já lida com distância se configurado,
    -- mas se precisar de ajuste fino:
    local xSound = exports.xsound
    if xSound and xSound:soundExists(id) then
        xSound:setVolume(id, volume)
    end
end
