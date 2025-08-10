-- Initialize variables
local serverWeather = "clear"
local serverTemperature = 20
local serverWindSpeed = 1.0
local serverHumidity = 50
local serverWindDirection = 0.0 -- degrees
local serverWindGust = 1.5      -- m/s
local serverCloudCover = 0.0    -- 0..1
local serverDewPoint = 10.0     -- °C

local weatherOptions = {"clear", "clouds", "overcast", "rain", "thunder", "foggy"}

local nativeWeatherMap = {
    [GetHashKey and GetHashKey('CLEAR')] = 'clear',
    [GetHashKey and GetHashKey('EXTRASUNNY')] = 'extrasunny',
    [GetHashKey and GetHashKey('CLOUDS')] = 'clouds',
    [GetHashKey and GetHashKey('OVERCAST')] = 'overcast',
    [GetHashKey and GetHashKey('RAIN')] = 'rain',
    [GetHashKey and GetHashKey('THUNDER')] = 'thunder',
    [GetHashKey and GetHashKey('FOGGY')] = 'foggy'
}

local function generatePseudoWeather()
    local hash = GetPrevWeatherTypeHashName and GetPrevWeatherTypeHashName()
    local nativeWeather = hash and nativeWeatherMap[hash]
    if nativeWeather then
        return nativeWeather
    end
    return weatherOptions[math.random(#weatherOptions)]
end

local function calculateWindSpeed(weatherType)
    local wind = GetWindSpeed and GetWindSpeed()
    if wind and wind > 0 then
        return wind
    end
    local windCfg = Config.EnhancedWeather and Config.EnhancedWeather.Wind
    if windCfg then
        local base = windCfg.baseSpeed[weatherType] or 1.0
        local variation = windCfg.variation[weatherType] or 0.5
        return base + (math.random() * variation)
    end
    return math.random(5, 25) / 10
end

-- Calculate dew point (Magnus formula)
local function calculateDewPoint(temp, humidity)
    local a, b = 17.27, 237.7
    local alpha = ((a * temp) / (b + temp)) + math.log(humidity / 100.0)
    return (b * alpha) / (a - alpha)
end

-- Estimate cloud cover (0..1) from weather type
local function calculateCloudCover(weatherType)
    local map = {
        extrasunny = 0.05, clear = 0.15, clouds = 0.5, overcast = 0.85,
        rain = 0.9, thunder = 0.95, foggy = 0.8, smog = 0.7,
        snow = 0.85, blizzard = 0.95
    }
    local k = string.lower(weatherType or 'clear')
    return map[k] or 0.2
end

-- Drifting wind direction (deg 0..360)
local function calculateWindDirection(prevDir, weatherType)
    local drift = 10
    local base = prevDir or math.random(0,359)
    local delta = math.random(-drift, drift)
    return (base + delta) % 360
end

-- Gust speed (>= base) depending on weather
local function calculateWindGust(base, weatherType)
    local w = base or 0.0
    local wt = string.lower(weatherType or 'clear')
    local factor = 1.0
    if wt == 'thunder' or wt == 'blizzard' then
        factor = 1.8
    elseif wt == 'rain' or wt == 'overcast' or wt == 'snow' then
        factor = 1.4
    else
        factor = 1.2
    end
    local gust = w + (math.random() * w * (factor - 1.0))
    if gust < w then gust = w end
    return gust
end

-- Internal temperature calculation using configuration data
local function calculateInternalTemperature()
    local weatherKey = string.lower(serverWeather)
    local hour

    if Config.weatherResource == 'renewed-weathersync' then
        local timeData = GlobalState.currentTime
        hour = timeData and timeData.hour or GetClockHours()
    else
        hour = GetClockHours()
    end

    local tempData = Config.Temperature[weatherKey]
    if tempData then
        for _, range in ipairs(tempData) do
            if hour >= range.startTime and hour < range.endTime then
                return (range.tempMin + range.tempMax) / 2
            end
        end
    end

    return serverTemperature
end

if not Config.useWeatherResourceTemp then
    serverTemperature = calculateInternalTemperature()
end

-- Provide server weather data for other resources
function getServerWeatherData()
    return serverTemperature, serverWeather, serverWindSpeed, serverHumidity
end

-- Allow other resources to programmatically set the temperature
function setServerTemperature(temp)
    if type(temp) == 'number' then
        serverTemperature = temp
        TriggerClientEvent('weather-temperature:syncData', -1, {
            temperature = serverTemperature
        })
        return true
    end
    return false
end

exports('getServerWeatherData', getServerWeatherData)
exports('setServerTemperature', setServerTemperature)

-- Framework initialization
local Framework = Config.Framework or 'standalone'

if Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
    if not ESX then
        print("^1[ERROR] ESX not found. Falling back to standalone.^7")
        Framework = 'standalone'
    end
elseif Framework == 'qbox' or Framework == 'qb-core' then
    QBCore = exports['qb-core']:GetCoreObject()
    if not QBCore then
        print("^1[ERROR] QBCore/QBox not found. Falling back to standalone.^7")
        Framework = 'standalone'
    end
end

-- Function to update player status based on framework
function UpdatePlayerStatus(playerId, statusName, changeAmount)
    if Framework == 'esx' then
        TriggerClientEvent('esx_status:add', playerId, statusName, changeAmount * 10000) -- ESX uses 0-1000000 scale
    elseif Framework == 'qbox' or Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            local currentStatus = Player.PlayerData.metadata[statusName] or 0
            local newStatus = currentStatus + changeAmount -- Positive increases, negative decreases
            newStatus = math.max(0, math.min(100, newStatus)) -- Clamp between 0 and 100
            Player.Functions.SetMetaData(statusName, newStatus)
        end
    end
end

-- Event handler for temperature updates
RegisterNetEvent('weather-temperature:updateStatus')
AddEventHandler('weather-temperature:updateStatus', function(statusName, changeAmount)
    local src = source
    UpdatePlayerStatus(src, statusName, changeAmount)
end)

-- Event handler for client requesting temperature data
RegisterNetEvent('weather-temperature:requestData')
AddEventHandler('weather-temperature:requestData', function()
    local src = source
    TriggerClientEvent('weather-temperature:syncData', src, {
        temperature = serverTemperature,
        windSpeed = serverWindSpeed,
        humidity = serverHumidity,
        weather = serverWeather,
        windDirection = serverWindDirection,
        windGust = serverWindGust,
        cloudCover = serverCloudCover,
        dewPoint = serverDewPoint,
    })
end)

-- Command to check server temperature
RegisterCommand('servertemp', function(source, args)
    local src = source
    
    -- Check if player has admin permissions
    if IsPlayerAceAllowed(src, "command.servertemp") then
        TriggerClientEvent('chat:addMessage', src, {
            color = {0, 200, 255},
            multiline = true,
            args = {"Temperature", string.format("Server Temp: %.1f°C | Weather: %s | Wind: %.1f m/s (dir %.0f°, gust %.1f) | Humidity: %d%% | Cloud: %.0f%% | Dew: %.1f°C",
                serverTemperature, serverWeather, serverWindSpeed, serverWindDirection, serverWindGust, serverHumidity, serverCloudCover*100, serverDewPoint)}
         })
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "You don't have permission to use this command."}
        })
    end
end, false)

-- Command to set server temperature
RegisterCommand('settemp', function(source, args, rawCommand)
    local src = source
    
    -- Check if player has admin permissions
    if IsPlayerAceAllowed(src, "command.settemp") then
        if args[1] and tonumber(args[1]) then
            serverTemperature = tonumber(args[1])
            TriggerClientEvent('weather-temperature:syncData', -1, {
                temperature = serverTemperature
            })
            TriggerClientEvent('chat:addMessage', src, {
                color = {0, 255, 0},
                multiline = true,
                args = {"System", "Temperature set to " .. serverTemperature .. "°C"}
            })
        else
            TriggerClientEvent('chat:addMessage', src, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Invalid temperature value. Usage: /settemp [value]"}
            })
        end
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "You don't have permission to use this command."}
        })
    end
end, false)

-- Thread to update server weather data
Citizen.CreateThread(function()
    while true do
        local resName = Config.weatherResource
        local resourceStarted = resName and GetResourceState(resName) == 'started'

        if resourceStarted and resName == 'renewed-weathersync' then
            serverWeather = GlobalState.weather and GlobalState.weather.weather or generatePseudoWeather()
            serverWindSpeed = GlobalState.windSpeed or calculateWindSpeed(serverWeather)
            if Config.useWeatherResourceTemp and GlobalState.temperature then
                serverTemperature = GlobalState.temperature
            else
                serverTemperature = calculateInternalTemperature()
            end
        else
            serverWeather = generatePseudoWeather()
            serverWindSpeed = calculateWindSpeed(serverWeather)
            serverTemperature = calculateInternalTemperature()
        end
        
        -- Update humidity based on weather
        if serverWeather == "rain" or serverWeather == "thunder" then
            serverHumidity = math.random(70, 95)
        elseif serverWeather == "foggy" then
            serverHumidity = math.random(60, 85)
        elseif serverWeather == "clear" or serverWeather == "extrasunny" then
            serverHumidity = math.random(30, 50)
        else
            serverHumidity = math.random(40, 70)
        end

        -- Derive additional fields
        serverCloudCover   = GlobalState.cloudCover   or calculateCloudCover(serverWeather)
        serverWindDirection= GlobalState.windDirection or calculateWindDirection(serverWindDirection, serverWeather)
        serverWindGust     = GlobalState.windGust     or calculateWindGust(serverWindSpeed, serverWeather)
        serverDewPoint     = calculateDewPoint(serverTemperature, serverHumidity)
         
        
        -- Broadcast weather data to all clients
        TriggerClientEvent('weather-temperature:syncData', -1, {
            temperature = serverTemperature,
            windSpeed = serverWindSpeed,
            humidity = serverHumidity,
            weather = serverWeather,
            windDirection = serverWindDirection,
            windGust = serverWindGust,
            cloudCover = serverCloudCover,
            dewPoint = serverDewPoint,
        })
        
        Citizen.Wait(60000) -- Update every minute
    end
end)

print('Weather and temperature server system initialized')






