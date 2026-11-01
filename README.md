# Venus Payphone

<p align="center">
  **A complete and customizable payphone system for FiveM.**
  <br/>
  Bringing classic public telephones back to life in Los Santos.
</p>

<p align="center">
  ![FiveM](https://img.shields.io/badge/FiveM-Resource-orange?style=flat-square)
  ![Lua](https://img.shields.io/badge/Lua-5.4-blue?style=flat-square)
  ![Version](https://img.shields.io/badge/Version-2.0.2-green?style=flat-square)
</p>

---

## Overview

**Venus Payphones** is a complete payphone system designed to bring interactive public telephones to your FiveM server.

Players can make and receive calls through configured payphones, browse a public phonebook, and communicate with other players using an immersive telephone experience.

The resource features a custom React-based NUI with two visual themes, configurable payphone locations, framework bridges, voice integration, and customizable sounds.

## Features

- **Custom NUI:** Modern React interface with two available themes.
- **Analog Theme:** Classic payphone experience with physical buttons and a CRT-style display.
- **Digital Theme:** Modern touchscreen-inspired interface.
- **Incoming & Outgoing Calls:** Players can make and receive calls through configured payphones.
- **Public Phonebook:** Browse available public payphone numbers.
- **Generic Payphones:** Use existing GTA V map telephone objects without manually configuring every location.
- **Custom Payphone Locations:** Configure your own telephone locations and numbers.
- **3D Ringtones:** World sounds that can be heard by nearby players.
- **Custom Sounds:** Configure MP3 ringtones and native GTA V sounds.
- **Voice Integration:** Uses pma-voice for telephone conversations.
- **Framework Support:** Standalone and Qbox (QBX) support.
- **Phone Integration:** Optional LB-Phone integration.
- **Call Costs:** Configure the price of telephone calls.
- **Configurable Cooldowns:** Prevent players from repeatedly using the same payphone.
- **Distance Validation:** Calls are automatically terminated when players move too far away.
- **Logging:** Console and Discord webhook logging support.
- **Localization:** English and Brazilian Portuguese translations.

## Dependencies

The following resources are required:

| Resource | Purpose |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | Shared utilities, callbacks and UI |
| [ox_target](https://github.com/overextended/ox_target) | Payphone interactions |
| [pma-voice](https://github.com/AvarianKnight/pma-voice) | Voice communication |

Make sure all dependencies are installed and started before `venus_payphones`.

## Installation

1. Download or clone this repository.
2. Place the `Venus_Payphone` folder inside your server's resources directory.
3. Ensure all dependencies are installed.
4. Configure `config.lua` according to your server.
5. Add the following to your `server.cfg`:

```cfg
ensure ox_lib
ensure ox_target
ensure pma-voice

ensure Venus_Payphone
```

6. Restart your server.

## Configuration

All main settings are managed through `config.lua`.

### Framework

```lua
Config.Framework = 'standalone'
```

Available options:

- `standalone`
- `qbx_core`

### Phone System

```lua
Config.PhoneSystem = 'none'
```

Available options:

- `none`
- `lb-phone`

### General Settings

```lua
Config.CallTimeout = 30
Config.HangupDistance = 3.5
Config.Cooldown = 10

Config.CallCost = 0
Config.CallCostItem = 'money'
```

| Setting | Description |
|---|---|
| `CallTimeout` | Time in seconds before an unanswered call expires. |
| `HangupDistance` | Maximum distance from the payphone before the call ends. |
| `Cooldown` | Cooldown after using a payphone. |
| `CallCost` | Cost of making a call. Set to `0` for free calls. |
| `CallCostItem` | Account or item used by the framework bridge. |

### Interface Themes

```lua
Config.PayphoneTheme = 'analog'
```

Available themes:

- `analog` – Classic payphone with physical buttons and CRT-inspired visuals.
- `digital` – Modern touchscreen-inspired interface.

### Custom Payphones

You can configure your own payphone locations:

```lua
Config.Payphones = {
    {
        label       = 'City Hall',
        number      = '1001',
        coords      = vec4(215.0, -810.0, 30.0, 160.0),
        spawnObject = false,
        private     = false,
    },
}
```

Each payphone supports additional options:

| Option | Description |
|---|---|
| `label` | Name displayed in the phonebook. |
| `number` | Unique dialable phone number. |
| `coords` | Position and heading using `vec4`. |
| `spawnObject` | Whether to spawn a payphone object. |
| `model` | Object model when spawning an object. |
| `private` | Hides the number from the public phonebook. |
| `incomingOnly` | Allows receiving calls without making outgoing calls. |

### Generic Payphones

The resource also supports existing GTA V payphone objects.

Players can interact with configured generic models to make outgoing calls without requiring individual phone number registrations.

```lua
Config.GenericModels = {
    `prop_phonebox_01b`,
    `prop_phonebox_01c`,
    `prop_phonebox_02`,
    `prop_phonebox_03`,
    `prop_phonebox_04`,
    `prop_phonebox_01a`,
    `p_phonebox_02_s`,
}
```

### Sound Configuration

Customize the sounds used throughout the telephone system.

```lua
Config.Sounds = {
    RingtoneWorld = {
        type = 'custom',
        file = 'ringtone.mp3',
        vol  = 0.1,
        dist = 30.0,
    },

    RingtoneLocal = {
        type = 'native',
        name = 'Phone_Ring_Tone',
        ref  = 'Phone_SoundSet_Michael'
    },
}
```

The resource supports native GTA V sounds and custom MP3 audio files.

### Logging

```lua
Config.Logs = {
    enabled = true,
    type    = 'both',
    webhook = '',
    color   = 16776960,
}
```

Available logging modes:

- `ox_lib`
- `webhook`
- `both`

**Note:** Keep your Discord webhook URL private. Never commit personal or server-specific credentials to a public repository.

## Localization

The resource includes:

- English (`en.json`)
- Brazilian Portuguese (`pt-br.json`)

Additional languages can be added through the `locales` directory.

## Technical Information

| Component | Technology |
|---|---|
| Game | FiveM / GTA V |
| Client & Server | Lua 5.4 |
| Interface | React |
| UI Communication | FiveM NUI |
| Target System | ox_target |
| Utilities | ox_lib |
| Voice | pma-voice |

## Contributing

Bug reports, suggestions and improvements are welcome.

If you find an issue or have an idea for improving the resource, feel free to open an issue or submit a pull request.

## Credits

**Developed by VenusNay**

Part of the **Venus Studio** ecosystem.

- GitHub: [@venusnay](https://github.com/venusnay)

---

<p align="center">
  **Venus Payphone**
  <br/>
  <i>Bringing communication back to the streets of Los Santos.</i>
</p>
