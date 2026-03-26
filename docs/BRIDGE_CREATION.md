# Payphones Bridge Creation Guide

This script uses a bridge system to remain framework-agnostic. You can easily adapt it to ESX, vRP, or your custom framework by following these steps.

## Directory Structure

Bridges are located in the `bridge/` directory:
- `bridge/standalone/`: Default fallback (no framework).
- `bridge/qbx_core/`: Example for Qbox/QBCore.
- `bridge/sounds/`: Audio plugin bridges (e.g., xsound).

## Creating a Framework Bridge

To create a new bridge (e.g., `esx`):

1. **Create a folder**: `bridge/esx/`
2. **Create client and server files**:
   - `bridge/esx/client.lua`
   - `bridge/esx/server.lua`

### Server-Side Requirements

Your `server.lua` must implement the `Bridge` global table with the following functions:

```lua
Bridge = Bridge or {}

-- Return player object
function Bridge.GetPlayer(source) end

-- Return unique identifier (citizenid/license/identifier)
function Bridge.GetIdentifier(source) end

-- Send notification to player
function Bridge.Notify(source, message, type) end

-- Remove money/checks from player
function Bridge.RemoveMoney(source, amount) end
```

### Client-Side Requirements

Your `client.lua` should handle local notifications:

```lua
BridgeClient = BridgeClient or {}

function BridgeClient.Notify(message, type) end
```

## Creating a Sound Bridge

If you want to use a different audio plugin instead of `xsound`:

1. Modify `bridge/sounds/xsound.lua` or create a new one.
2. Implement `SoundBridge.Play(type, id, file, options)` and `SoundBridge.Stop(id)`.

## Registering the Bridge

Once your files are created, add them to `fxmanifest.lua`:

```lua
client_scripts {
    'bridge/esx/client.lua',
    ...
}
server_scripts {
    'bridge/esx/server.lua',
    ...
}
```

And update `Config.Framework` in `config.lua` to match your new framework name.
