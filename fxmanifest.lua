fx_version 'cerulean'
game 'gta5'

name        'payphones'
description 'Complete payphones system for FiveM'
author      'dev'
version     '1.2.0'

escrow_ignore {
    'config.lua',
    'locales/*.json',
    'bridge/**/*.lua',
    'sounds/*.mp3',
    'docs/*.md',
}

lua54 'yes'

files {
    -- Include MP3s and locales
    'sounds/*.mp3',
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'bridge/frameworks/**/client.lua',
    'bridge/sounds/*.lua',
    'client/animations.lua',
    'client/sounds.lua',
    'client/calls.lua',
    'client/main.lua',
}

server_scripts {
    'bridge/frameworks/**/server.lua',
    'bridge/phones/*.lua',
    'server/logs.lua',
    'server/calls.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'pma-voice',
}
