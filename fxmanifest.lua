fx_version 'cerulean'
game 'gta5'

name        'payphones'
description 'Complete payphones system for FiveM'
author      'dev'
version     '2.0.0'

escrow_ignore {
    'config.lua',
    'locales/*.json',
    'bridge/**/*.lua',
    'sounds/*.mp3',
    'docs/*.md',
    'html/**/*',
}

lua54 'yes'

-- NUI (React interface)
ui_page 'html/index.html'

files {
    -- Include MP3s and locales
    'sounds/*.mp3',
    'locales/*.json',
    -- NUI files
    'html/index.html',
    'html/assets/*.js',
    'html/assets/*.css',
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
    'client/nui.lua',
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
