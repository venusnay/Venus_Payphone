# Payphones Bridge Creation Guide

This script uses a modular bridge system to remain framework-agnostic and compatible with multiple phone systems.

## Directory Structure

Bridges are separated into three categories in the `bridge/` directory:
- `bridge/frameworks/`: Framework-specific logic (ESX, QBox, Standalone).
- `bridge/phones/`: Integration with existing phone scripts (lb-phone, none).
- `bridge/sounds/`: Audio plugin bridges (e.g., xsound).

## 1. Creating a Framework Bridge

To add support for a new framework (e.g., `esx`):

1. **Create a folder**: `bridge/frameworks/esx/`
2. **Create client and server files**:
   - `bridge/frameworks/esx/client.lua`
   - `bridge/frameworks/esx/server.lua`

### Server-Side Requirements

Your `server.lua` must implement the `Bridge` global table.

**Mandatory Functions:**
```lua
Bridge = Bridge or {}

-- Send notification to player
---@param ntype string 'success'|'error'|'inform'|'warning'
function Bridge.Notify(source, message, ntype) end

-- Remove money/items from player (returns true/false)
function Bridge.RemoveMoney(source, amount) end
```

**Optional/Internal Functions (not currently required by core):**
- `Bridge.GetPlayer(source)`
- `Bridge.GetIdentifier(source)`

### Client-Side Requirements

Your `client.lua` handles local notifications:

```lua
BridgeClient = BridgeClient or {}

function BridgeClient.Notify(message, ntype) end
```

---

## 2. Creating a Phone System Bridge

If you want to integrate with a custom phone system (so payphones can call players' phones):

1. **Create a file**: `bridge/phones/myphone.lua`
2. **Implement `PhoneBridge`**:

```lua
if Config.PhoneSystem == 'myphone' then
    PhoneBridge = {}

    function PhoneBridge.CreateCall(source, payphoneId, payphoneNumber, targetNumber)
        -- Start call to targetNumber, return a table with { callId = ... } or nil
    end

    function PhoneBridge.EndCall(source) end

    function PhoneBridge.IsInCall(source) end
end
```

---

## 3. Creating a Sound Bridge

For custom audio plugins (other than `xsound`):

1. Modify `bridge/sounds/xsound.lua` or create a new plugin file.
2. Implement:
   - `SoundBridge.Play(type, id, file, options)`
   - `SoundBridge.Stop(id)`

---

## Registering the Bridge

The `fxmanifest.lua` uses wildcards to automatically load files in the `bridge/` subdirectories:

```lua
'bridge/frameworks/**/client.lua'
'bridge/frameworks/**/server.lua'
'bridge/phones/*.lua'
```

**Steps to activate:**
1. Follow the naming convention above.
2. Ensure each file starts with a check: `if Config.Framework ~= 'your_framework' then return end`.
3. Update `Config.Framework` and `Config.PhoneSystem` in `config.lua` to match your identifiers.

