-- Weather/Temperature server (stable minimal)
local serverWeather = "clear"
local serverTemperature = 20.0
local serverWindSpeed = 2.0
local serverHumidity = 50
local serverWindDirection = 0.0
local serverWindGust = 3.0
local serverCloudCover = 0.2
local serverDewPoint = 10.0

local weatherOptions = {"clear","clouds","overcast","rain","thunder","foggy","snow","blizzard"}

local function generatePseudoWeather()
    return weatherOptions[math.random(#weatherOptions)]
end

local function calculateInternalTemperature()
    local w = serverWeather
    if w == "blizzard" or w == "snow" then return math.random(-15,-5) end
    if w == "rain" or w == "foggy" then return math.random(5,15) end
    return math.random(15,28)
end

local function recalc()
    if not Config or not Config.weatherResource then
        serverWeather = generatePseudoWeather()
        serverTemperature = calculateInternalTemperature()
        serverWindSpeed = math.random(5,25)/10
        serverWindDirection = math.random(0,359)
        serverWindGust = serverWindSpeed * (serverWeather=="blizzard" and 1.8 or 1.3)
        serverCloudCover = ({clear=0.1, clouds=0.5, overcast=0.8, rain=0.9, thunder=1.0, foggy=0.6, snow=0.7, blizzard=1.0})[serverWeather] or 0.3
        serverDewPoint = math.max(-20, serverTemperature - math.random(0,6))
    end
end

function getServerWeatherData()
    return serverTemperature, serverWeather, serverWindSpeed, serverHumidity
end
exports('getServerWeatherData', getServerWeatherData)

function setServerTemperature(temp)
    if type(temp)=='number' then
        serverTemperature = temp
        TriggerClientEvent('weather-temperature:syncData', -1, { temperature = serverTemperature })
        return true
    end
    return false
end
exports('setServerTemperature', setServerTemperature)

RegisterNetEvent('weather-temperature:requestSync', function()
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

CreateThread(function()
    while true do
        recalc()
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
        Wait(60000)
    end
end)

print('[weather-temperature] server initialized')
