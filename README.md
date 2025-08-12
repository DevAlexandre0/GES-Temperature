# GES Temperature

A lightweight survival helper that simulates ambient temperature, wetness and stamina for FiveM players.

## What it does
- Calculates world temperature from weather, time, altitude, biome and nearby water
- Raises or lowers player risk and drains hunger/thirst when conditions are extreme
- Tracks wetness and stamina, including optional heat zone support
- Sends updates to the server and exposes exports so other resources can read the values
- Detects ESX, QBCore, ox_lib and GES-SurvCore automatically; works standalone if nothing is present

## Getting started
1. Drop the folder in your `resources` directory
2. Add `ensure GES-Temperature` in `server.cfg`
3. Tweak options in `config.lua` (enable heat zones, stamina modifiers, etc.)

## Using the data
Other scripts can pull the latest stats:
```lua
local temp = exports['GES-Temperature']:getTemperatureData(source)
local wet  = exports['GES-Temperature']:getWetnessData(source)
local stam = exports['GES-Temperature']:getStaminaData(source)
```

These values update every few seconds and can drive your own gameplay effects.

## Optional integrations
- **ox_lib** for nicer notifications
- **ESX / QBCore** to apply hunger and thirst drains
- **GES-SurvCore** if installed; otherwise this resource stores data itself

## Credits
Made by GES – pull requests are welcome.
