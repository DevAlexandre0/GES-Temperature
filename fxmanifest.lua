fx_version 'cerulean'
game 'gta5'

name 'weather-temperature'
description 'Standalone weather and temperature system'
author 'Your Name'
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



