--[[
    client/main.lua
    Client entry point:
    - Spawning configured objects
    - Registering ox_target zones per payphone
    - Managing local UI and phone states
]]

lib.locale()

-- References to spawned objects
local spawnedObjects = {}

-- Local states for each payphone (status, extra, etc.)
local payphoneStates = {}

-- Local cooldowns per payphoneId
local cooldowns = {}

-- ─────────────────────────────────────────────
--  OBJECT SPAWNING
-- ─────────────────────────────────────────────

--- Spawns a payphone object at its configured position.
---@param phone table
local function SpawnPayphoneObject(phone)
    if spawnedObjects[phone.id] then return end

    local model = phone.model
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local obj = CreateObject(
        model,
        phone.coords.x,
        phone.coords.y,
        phone.coords.z,
        false,  -- isNetwork
        false,  -- bScriptHostObj
        false   -- dynamic
    )

    SetEntityHeading(obj, phone.coords.w)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    SetModelAsNoLongerNeeded(model)

    spawnedObjects[phone.id] = obj
end

--- Removes a payphone's spawned object.
---@param phoneId string
local function DeletePayphoneObject(phoneId)
    if spawnedObjects[phoneId] then
        DeleteEntity(spawnedObjects[phoneId])
        spawnedObjects[phoneId] = nil
    end
end

-- ─────────────────────────────────────────────
--  3D SOUND & VISUAL CONTROL (RINGING)
-- ─────────────────────────────────────────────

-- ─────────────────────────────────────────────
--  3D SOUND & VISUAL CONTROL (RINGING)
--  Using lib.points for maximum performance
-- ─────────────────────────────────────────────

local ringPoints = {}

local function CreateRingingPoint(phone)
    if ringPoints[phone.id] then return end

    local phoneCoords = vector3(phone.coords.x, phone.coords.y, phone.coords.z)
    local sWorld = Config.Sounds.RingtoneWorld
    local maxDist = sWorld.dist or 30.0

    ringPoints[phone.id] = lib.points.new({
        coords = phoneCoords,
        distance = maxDist,
        payphoneId = phone.id,
        phoneData = phone,
        nearby = function(self)
            -- VISUAL EFFECT: Glow above the payphone
            local markerPos = self.coords + vector3(0.0, 0.0, 1.25)
            DrawMarker(1, markerPos.x, markerPos.y, markerPos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 0, 150, true, true, 2, nil, nil, false)
            DrawMarker(20, markerPos.x, markerPos.y, markerPos.z + 0.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.4, 0.4, 0.4, 255, 255, 0, 200, false, true, 2, true, nil, nil, false)

            -- SOUND EFFECT: Trigger ringtone if not already playing
            if not IsRingtoneActive(self.payphoneId) then
                local phoneObject = spawnedObjects[self.payphoneId]
                if not phoneObject or not DoesEntityExist(phoneObject) then
                    phoneObject = GetClosestObjectOfType(self.coords.x, self.coords.y, self.coords.z, 2.0, self.phoneData.model or `prop_phonebox_01c`, false, false, false)
                end
                PlayRingtoneAtEntityOrCoords(self.payphoneId, phoneObject, self.coords)
            end
        end,
        onLeave = function(self)
            StopRingtoneAtCoords(self.payphoneId)
        end
    })
end

local function RemoveRingingPoint(phoneId)
    if ringPoints[phoneId] then
        ringPoints[phoneId]:remove()
        ringPoints[phoneId] = nil
        StopRingtoneAtCoords(phoneId)
    end
end

-- ─────────────────────────────────────────────
--  OX_TARGET ZONE REGISTRATION
-- ─────────────────────────────────────────────

--- Opens the public phonebook menu.
function OpenPhonebook()
    local options = {}

    for _, phone in ipairs(Config.Payphones) do
        if not phone.private then
            table.insert(options, {
                title       = phone.label or (locale('use_payphone') .. ' ' .. phone.number),
                description = locale('dial_input_label') .. ': ' .. phone.number,
                icon        = 'phone',
                onSelect    = function()
                    -- Copy to clipboard for easy dialing
                    lib.setClipboard(phone.number)
                    BridgeClient.Notify(locale('phonebook_copy_success'):format(phone.number), 'inform')
                end,
            })
        end
    end

    if #options == 0 then
        BridgeClient.Notify(locale('phonebook_no_numbers'), 'inform')
        return
    end

    lib.registerContext({
        id      = 'payphone_phonebook',
        title   = locale('phonebook_title'),
        options = options,
    })
    lib.showContext('payphone_phonebook')
end

--- Checks if an entity is already registered as a fixed payphone.
---@param entity number
---@return boolean
local function IsEntityRegisteredPayphone(entity)
    local entityCoords = GetEntityCoords(entity)
    for _, phone in ipairs(Config.Payphones) do
        local phoneCoords = vector3(phone.coords.x, phone.coords.y, phone.coords.z)
        if #(entityCoords - phoneCoords) < 2.0 then
            return true
        end
    end
    return false
end

--- Returns ox_target options for a payphone based on its current state.
---@param phone table
---@param isGeneric boolean|nil
---@return table
local function BuildTargetOptions(phone, isGeneric)
    local status = payphoneStates[phone.id] and payphoneStates[phone.id].status or 'idle'
    local callerStr = (status == 'ringing' and payphoneStates[phone.id].extra) and payphoneStates[phone.id].extra.callerNumber or 'Unknown'

    local options = {}

    -- Only show fixed info for non-generic phones
    if not isGeneric then
        table.insert(options, {
            name  = 'payphone_info_' .. phone.id,
            icon  = 'fas fa-id-card',
            label = locale('check_number'),
            onSelect = function()
                BridgeClient.Notify(locale('payphone_number_info'):format(phone.number), 'inform')
            end,
            distance = 2.0,
        })
        table.insert(options, {
            name  = 'payphone_list_' .. phone.id,
            icon  = 'fas fa-address-book',
            label = locale('phonebook_title'),
            onSelect = function()
                OpenPhonebook()
            end,
            distance = 2.0,
        })
    end

    if not phone.incomingOnly then
        table.insert(options, {
            name  = 'payphone_use_' .. phone.id,
            icon  = 'fas fa-phone',
            label = isGeneric and locale('use_payphone_outgoing') or locale('use_payphone'),
            canInteract = function(entity)
                if IsPlayerInCall() then return false end

                -- Prevent generic menu on fixed payphones
                if isGeneric and IsEntityRegisteredPayphone(entity) then return false end

                local status = payphoneStates[phone.id] and payphoneStates[phone.id].status or 'idle'
                return status == 'idle'
            end,
            onSelect = function()
                if cooldowns[phone.id] and GetGameTimer() < cooldowns[phone.id] then
                    BridgeClient.Notify(locale('cooldown_wait'), 'warning')
                    return
                end
                OpenDialMenu(phone.id, isGeneric)
            end,
            distance = 2.0,
        })
    end

    if not isGeneric then
        table.insert(options, {
            name  = 'payphone_answer_' .. phone.id,
            icon  = 'fas fa-phone-volume',
            label = locale('answer_call_from'):format(callerStr),
            canInteract = function()
                if IsPlayerInCall() then return false end
                local status = payphoneStates[phone.id] and payphoneStates[phone.id].status or 'idle'
                return status == 'ringing'
            end,
            onSelect = function()
                AcceptIncomingCall(phone.id)
            end,
            distance = 2.0,
        })
        table.insert(options, {
            name  = 'payphone_reject_' .. phone.id,
            icon  = 'fas fa-phone-slash',
            label = locale('reject_call'),
            canInteract = function()
                if IsPlayerInCall() then return false end
                local status = payphoneStates[phone.id] and payphoneStates[phone.id].status or 'idle'
                return status == 'ringing'
            end,
            onSelect = function()
                RejectIncomingCall(phone.id)
            end,
            distance = 2.0,
        })
    end

    -- DEBUG TOOL: Copy config data from generic phone
    if Config.Debug and isGeneric then
        table.insert(options, {
            name  = 'payphone_debug_copy',
            icon  = 'fas fa-copy',
            label = locale('dev_copy_config'),
            onSelect = function(data)
                local coords = GetEntityCoords(data.entity)
                local heading = GetEntityHeading(data.entity)
                local model = GetEntityModel(data.entity)

                -- Get street name for the label
                local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local street = GetStreetNameFromHashKey(s1)
                if s2 ~= 0 then
                    street = street .. " / " .. GetStreetNameFromHashKey(s2)
                end

                local str = string.format(
                    "{\n    label       = '%s',\n    number      = 'XXXX',\n    coords      = vec4(%.2f, %.2f, %.2f, %.2f),\n    spawnObject = false,\n    model       = %s,\n    private     = false,\n},",
                    street, coords.x, coords.y, coords.z, heading, model
                )
                lib.setClipboard(str)
                BridgeClient.Notify(locale('dev_copy_success'):format(street), 'success')
            end,
            distance = 2.0,
        })
    end

    table.insert(options, {
        name  = 'payphone_hangup_' .. phone.id,
        icon  = 'fas fa-phone-slash',
        label = locale('hang_up'),
        canInteract = function(entity)
            if isGeneric and IsEntityRegisteredPayphone(entity) then return false end
            return GetActiveCallPhoneId() == phone.id
        end,
        onSelect = function()
            TriggerServerEvent('payphones:server:hangup', {
                payphoneId = phone.id,
                reason     = 'hangup',
            })
            PlayDisconnectSound()
            CleanupCallState()
            BridgeClient.Notify('Call ended.', 'inform')
        end,
        distance = 2.0,
    })

    return options
end

--- Registers the target zone for a payphone.
---@param phone table
local function RegisterPayphoneTarget(phone)
    local coords = vector3(phone.coords.x, phone.coords.y, phone.coords.z)

    exports.ox_target:addSphereZone({
        coords   = coords,
        radius   = 1.5,
        name     = 'payphone_zone_' .. phone.id,
        debug    = false,
        options  = BuildTargetOptions(phone, false),
    })
end

--- Returns the state of a payphone (used by calls.lua).
---@param payphoneId string
---@return table|nil
function GetLocalPayphoneState(payphoneId)
    return payphoneStates[payphoneId]
end

-- ─────────────────────────────────────────────
--  INITIALIZATION
-- ─────────────────────────────────────────────

CreateThread(function()
    -- Ensure IDs are initialized correctly
    InitializePayphones()

    -- Pre-load sound banks for native sounds
    RequestScriptAudioBank("Phone_SoundSet_Default", false)
    RequestScriptAudioBank("Phone_SoundSet_Michael", false)

    -- Small wait to ensure world data is loaded
    Wait(2000)

    for _, phone in ipairs(Config.Payphones) do
        -- Initialize default state
        payphoneStates[phone.id] = { status = 'idle' }

        -- Spawn object if required
        if phone.spawnObject and phone.model then
            SpawnPayphoneObject(phone)
        end

        -- Register interaction zones for fixed phones
        RegisterPayphoneTarget(phone)
    end

    -- Register interaction for generic map phones (outgoing only)
    if Config.GenericModels and #Config.GenericModels > 0 then
        exports.ox_target:addModel(Config.GenericModels, BuildTargetOptions({
            id = 'generic', -- Shared ID prefix for generic phones
            number = 'Unknown',
            coords = vec3(0,0,0) -- Not used for generic target
        }, true))
    end

    -- Sync states with server
    TriggerServerEvent('payphones:server:syncStates')
end)

-- ─────────────────────────────────────────────
--  COOLDOWN MANAGEMENT
-- ─────────────────────────────────────────────

--- Applies cooldown to a payphone after use.
---@param payphoneId string
function ApplyLocalCooldown(payphoneId)
    cooldowns[payphoneId] = GetGameTimer() + (Config.Cooldown * 1000)
end

-- Server notifies when the local player's call has ended (triggering cooldown)
RegisterNetEvent('payphones:client:applyCooldown', function(payphoneId)
    ApplyLocalCooldown(payphoneId)
end)

-- ─────────────────────────────────────────────
--  EVENT: PAYPHONE STATE UPDATED
-- ─────────────────────────────────────────────

RegisterNetEvent('payphones:client:stateUpdate', function(data)
    -- data: { payphoneId, status, extra }
    payphoneStates[data.payphoneId] = { status = data.status, extra = data.extra }

    if data.status == 'ringing' then
        local phone = GetPayphoneById(data.payphoneId)
        if phone then
            CreateRingingPoint(phone)
        end
    else
        RemoveRingingPoint(data.payphoneId)
    end
end)

-- ─────────────────────────────────────────────
--  RESOURCE CLEANUP
-- ─────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Remove spawned objects
    for id, _ in pairs(spawnedObjects) do
        DeletePayphoneObject(id)
    end

    -- Remove target zones and stop sounds
    for _, phone in ipairs(Config.Payphones) do
        if phone.id then
            exports.ox_target:removeZone('payphone_zone_' .. phone.id)
            RemoveRingingPoint(phone.id)
        end
    end

    -- Clear active call state
    CleanupCallState()
end)
