-- Initialize variables
local playerTemperatures = {}
local serverWeather = "clear"
local serverTemperature = 20
local serverWindSpeed = 1.0
local serverHumidity = 50

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
        weather = serverWeather
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
            args = {"Temperature", string.format("Server Temperature: %.1f°C | Weather: %s | Wind: %.1f m/s | Humidity: %d%%", 
                serverTemperature, serverWeather, serverWindSpeed, serverHumidity)}
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
        -- Get weather data from weather resource if available
        if Config.weatherResource == 'renewed-weathersync' then
            serverWeather = GlobalState.weather and GlobalState.weather.weather or "clear"
            serverTemperature = GlobalState.temperature or 20
            serverWindSpeed = GlobalState.windSpeed or 1.0
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
        
        -- Broadcast weather data to all clients
        TriggerClientEvent('weather-temperature:syncData', -1, {
            temperature = serverTemperature,
            windSpeed = serverWindSpeed,
            humidity = serverHumidity,
            weather = serverWeather
        })
        
        Citizen.Wait(60000) -- Update every minute
    end
end)

print('Weather and temperature server system initialized')

