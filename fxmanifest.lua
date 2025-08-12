fx_version 'cerulean'
game 'gta5'

name 'GES-Temperature'
description 'Combined Temperature + Wetness + Stamina modules with SurvCore-aware bridge'
author 'GES'
version '1.1.0'
lua54 'yes'

-- debug: setr ges_debug 1
shared_scripts {
  'config/config.temperature.lua',
  'config/config.wetness.lua',
  'config/config.stamina.lua',
}

client_scripts {
  'client/main.lua',                -- smart bridge (SurvCore-aware)
  'client/module.temperature.lua',
  'client/module.wetness.lua',
  'client/module.stamina.lua',
}

server_scripts {
  'server/bridge.lua'               -- optional logging/future hooks
}

exports {
  'getTemperatureData',
  'getWetnessData',
  'getStaminaData'
}
