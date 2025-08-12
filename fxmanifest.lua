fx_version 'cerulean'
game 'gta5'

name 'GES-Temperature'
description 'Standalone weather and temperature system'
author 'GESUS'
version '1.0.0'
lua54 'yes'
shared_scripts {
    -- '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

exports {
    'getTemperatureData'
}

server_export 'getServerWeatherData'
server_export 'setServerTemperature'

