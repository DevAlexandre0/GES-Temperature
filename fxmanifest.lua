fx_version 'cerulean'
game 'gta5'

name 'GES-Temperature'
description 'Combined Temperature + Wetness + Stamina modules with SurvCore-aware bridge'
author 'GES'
version '1.1.0'
lua54 'yes'

-- debug: setr ges_debug 1

shared_script 'config.lua'

client_scripts {
    'client.lua',              -- core calculations
    'client/main.lua',         -- event bridge / framework helpers
    'client/modules/temperature.lua',
    'client/modules/wetness.lua',
    'client/modules/stamina.lua'
}

server_scripts {
    'server/bridge.lua'
}

exports {
    'getTemperatureData',
    'getWetnessData',
    'getStaminaData'
}
