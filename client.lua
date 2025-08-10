-- Local variables
local currentTemperature = 0
local lastUpdateTime = 0
local temperatureHistory = {}
local windSpeed = 0
local humidity = 50 -- Default humidity (%)
local barometricPressure = 1013 -- Default pressure (hPa)
local dewPoint = 0
local feelsLikeTemperature = 0
local lastWeatherCheck = 0
local weatherTransitionTime = 0
local isIndoors = false
local nearbyWaterBodies = {}
local biomeType = "default"
local timeOfDay = "day"
local sunriseTime = 6 -- 6:00 AM
local sunsetTime = 18 -- 6:00 PM
local Zones = {}
local Framework = Config.Framework or 'standalone'

-- Extended environment vars (from server sync)
local cloudCover = 0.0    -- 0..1
local windDirection = 0.0 -- degrees
local windGust = 0.0      -- m/s

-- Thermal risk state
local currentRisk = "none"
local riskSeverity = 0

-- Simple wetness model (0..1)
local WET = { level = 0.0, dryRate = 0.02, rainGain = 0.08, waterGain = 0.25 }

-- Debug toggle
local TEMPDEBUG = false

-- Basic notification helper using the chat resource
local function notify(title, message)
    TriggerEvent('chat:addMessage', { args = { title or 'Info', message or '' } })
end

-- Cache common functions for performance
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max
local mathRandom = math.random
local mathSin = math.sin
local mathExp = math.exp
local mathAbs = math.abs
local mathLog = math.log

-- Initialize temperature history with default values
for i = 1, 10 do
    temperatureHistory[i] = 15 -- Default moderate temperature
end

-- Add temperature to history and get smoothed value with improved algorithm
local function addTemperatureToHistory(temp)
    -- Shift all values
    for i = 10, 2, -1 do
        temperatureHistory[i] = temperatureHistory[i-1]
    end
    temperatureHistory[1] = temp
    
    -- Calculate exponential weighted moving average for smoother transitions
    local sum = 0
    local weights = 0
    for i = 1, 10 do
        local weight = mathExp(-(i-1) * 0.3) -- Exponential decay factor
        sum = sum + (temperatureHistory[i] * weight)
        weights = weights + weight
    end
    
    return sum / weights
end

-- Get current season based on game month with improved accuracy
local function getCurrentSeason()
    local month
    local day
    
    if Config.weatherResource == 'renewed-weathersync' then
        month = GlobalState.currentMonth or 1
        day = GlobalState.currentDay or 15
    else
        month = tonumber(GetClockMonth()) + 1 -- FiveM native (0-based index, so +1)
        day = tonumber(GetClockDayOfMonth())
    end
    
    -- More accurate seasonal transitions based on meteorological seasons
    if (month == 3 and day >= 21) or (month > 3 and month < 6) or (month == 6 and day < 21) then
        return "spring"
    elseif (month == 6 and day >= 21) or (month > 6 and month < 9) or (month == 9 and day < 21) then
        return "summer"
    elseif (month == 9 and day >= 21) or (month > 9 and month < 12) or (month == 12 and day < 21) then
        return "autumn"
    else
        return "winter"
    end
end

-- Get wind chill factor with improved formula - optimized
local function getWindChillFactor()
    -- Only recalculate wind every minute for performance
    local gameTime = GetGameTimer() / 1000
    if gameTime - lastWeatherCheck > 60 then
        lastWeatherCheck = gameTime
        
        if Config.weatherResource == 'renewed-weathersync' then
            windSpeed = GlobalState.windSpeed or mathRandom(0, 30) / 10
        else
            -- Simulate wind based on weather with more variation
            local weather = getCurrentWeather()
            local baseSpeed = 0
            local variation = 0
            
            -- Use a lookup table for weather types for better performance
            local weatherData = {
                thunder = {3.5, 1.5},
                blizzard = {3.5, 1.5},
                rain = {2.0, 1.0},
                snow = {2.0, 1.0},
                foggy = {1.0, 0.5},
                clouds = {1.0, 0.5},
                clear = {0.5, 0.5},
                extrasunny = {0.5, 0.5}
            }
            
            local data = weatherData[weather:lower()] or {0.5, 0.5}
            baseSpeed, variation = data[1], data[2]
            
            -- Add time-based variation (windier during day, calmer at night)
            local hour = getCurrentTime()
            local timeFactor = 1.0
            
            -- Simplified time factor calculation
            if hour >= 10 and hour <= 16 then
                timeFactor = 1.2 -- Windier during mid-day
            elseif hour >= 0 and hour <= 5 then
                timeFactor = 0.8 -- Calmer during night
            end
            
            -- Add some randomness with smoother variation
            local noise = mathSin(gameTime * 0.001) * 0.5 + 0.5
            windSpeed = (baseSpeed + (noise * variation)) * timeFactor
        end
    end
    
    -- Only apply wind chill if temperature is below 10°C and wind speed is above 1.3 m/s
    if currentTemperature < 10 and windSpeed > 1.3 then
        -- Improved wind chill formula (JAG/TI method)
        local windSpeedKmh = windSpeed * 3.6 -- Convert m/s to km/h
        local windPow = windSpeedKmh^0.16 -- Calculate this once for reuse
        local windChill = 13.12 + 0.6215 * currentTemperature - 11.37 * windPow + 0.3965 * currentTemperature * windPow
        
        -- Return the difference between actual temperature and wind chill
        return mathMax(0, currentTemperature - windChill)
    end
    
    return 0 -- No wind chill effect
end

Get heat index (Rothfusz) - returns EXTRA °C above actual (0 if not applicable)
local function getHeatIndex()
    if currentTemperature >= 27 and humidity >= 40 then
        local Tf = currentTemperature * 9/5 + 32.0
        local RH = humidity

        local HI = -42.379 + 2.04901523*Tf + 10.14333127*RH
                  - 0.22475541*Tf*RH - 6.83783e-3*(Tf*Tf)
                  - 5.481717e-2*(RH*RH) + 1.22874e-3*(Tf*Tf)*RH
                  + 8.5282e-4*Tf*(RH*RH) - 1.99e-6*(Tf*Tf)*(RH*RH)
        local HIc = (HI - 32.0) * 5.0/9.0
        return mathMax(0, HIc - currentTemperature)
    end
    
    return 0
end

-- Get altitude temperature modifier (standard lapse rate ~6.5°C/km)
local function getAltitudeModifier()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local altitude = playerCoords.z
    if altitude <= 0 then return 0 end
    return -0.0065 * altitude
end

-- Get time of day temperature modifier with improved curve - optimized
local function getTimeModifier()
    local hour = getCurrentTime()
    
    -- Update time of day status for other calculations
    timeOfDay = (hour >= sunriseTime and hour < sunsetTime) and "day" or "night"
    
    -- More realistic temperature curve throughout the day
    -- Coldest around 5-6 AM, warmest around 2-3 PM
    local peakHour = 14 -- 2 PM
    local troughHour = 5 -- 5 AM
    
    -- Calculate hours from trough (normalized to 0-24 range)
    local hoursFromTrough = (hour - troughHour) % 24
    
    -- Calculate temperature variation based on distance from peak/trough
    -- Use a simpler approach for performance
    if hoursFromTrough < 12 then
        -- Rising temperature (morning to afternoon)
        return mathSin((hoursFromTrough / 12) * (math.pi / 2)) * 8
    else
        -- Falling temperature (afternoon to night)
        return mathSin(((24 - hoursFromTrough) / 12) * (math.pi / 2)) * 8
    end
end

-- Get seasonal base temperature with more realistic variation - optimized
local function getSeasonalBaseTemperature()
    local season = getCurrentSeason()
    local hour = getCurrentTime()
    local dayNightFactor = (hour >= sunriseTime and hour < sunsetTime) and 1.0 or 0.7
    
    -- Get base temperature range for the season
    -- Use a lookup table for better performance
    local seasonRanges = {
        winter = {-10, 5},
        spring = {5, 20},
        summer = {15, 30},
        autumn = {5, 20}
    }
    
    local range = seasonRanges[season] or {5, 20}
    local minTemp = range[1] * dayNightFactor
    local maxTemp = range[2] * dayNightFactor
    
    -- Add some daily variation using perlin-like noise
    local gameTime = GetGameTimer() / 1000
    local dayVariation = mathSin(gameTime * 0.0001) * 2 -- Slow variation over days
    
    -- Calculate temperature within range with some randomness
    local baseTemp = minTemp + (mathRandom() * (maxTemp - minTemp))
    return baseTemp + dayVariation
end

-- Get weather temperature modifier with improved realism - optimized
local function getWeatherModifier(weather)
    weather = weather or getCurrentWeather()
    
    -- Use a lookup table for better performance
    local modifiers = {
        extrasunny = {5, 10},
        clear = {2, 5},
        clouds = {0, 3},
        smog = {-2, 2},
        foggy = {-3, 0},
        overcast = {-4, -1},
        rain = {-6, -3},
        thunder = {-8, -4},
        snow = {-15, -8},
        snowlight = {-10, -5},
        blizzard = {-25, -15},
        xmas = {-15, -8}
    }
    
    -- Get modifier range for current weather
    local modifier = modifiers[weather:lower()] or {0, 0}
    
    -- Calculate modifier with some persistence
    local persistenceFactor = 0.7
    local previousModifier = 0
    local newModifier = modifier[1] + (mathRandom() * (modifier[2] - modifier[1]))
    
    return previousModifier * persistenceFactor + newModifier * (1 - persistenceFactor)
end

-- Get roof state (check if player is indoors) - optimized
function GetRoofState()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Use a simpler ray cast with fewer arguments
    local ray = StartShapeTestRay(
        playerCoords.x, playerCoords.y, playerCoords.z + 0.5,
        playerCoords.x, playerCoords.y, playerCoords.z + 50.0,
        1, playerPed, 0
    )
    
    local _, hit = GetShapeTestResult(ray)
    return hit == 1
end

-- Get clothing insulation based on player model and components - optimized
function getClothingInsulation()
    local playerPed = PlayerPedId()
    local insulation = 0
    
    -- Check if player is wearing winter clothing
    local torsoDrawable = GetPedDrawableVariation(playerPed, 11) -- Torso component
    local legsDrawable = GetPedDrawableVariation(playerPed, 4) -- Legs component
    local upperDrawable = GetPedDrawableVariation(playerPed, 3) -- Upper body
    
    -- Use range checks instead of multiple comparisons
    -- Heavy jackets (certain torso drawables)
    if torsoDrawable >= 10 and torsoDrawable <= 15 then
        insulation = insulation + 30
    elseif torsoDrawable >= 16 and torsoDrawable <= 20 then
        insulation = insulation + 20
    else
        insulation = insulation + 10
    end
    
    -- Long sleeves add insulation
    if upperDrawable >= 5 and upperDrawable <= 10 then
        insulation = insulation + 10
    end
    
    -- Long pants add insulation
    if legsDrawable >= 4 and legsDrawable <= 10 then
        insulation = insulation + 15
    end
    
    return mathMin(insulation, 70) -- Cap at 70% insulation
end

-- ===== Microclimate & Exposure Helpers =====
-- Sun exposure check (raycast upward)
local function isInSun()
    local ped = PlayerPedId()
    local head = GetPedBoneCoords(ped, 0x796E, 0.0, 0.0, 0.0) -- head bone
    local dest = vector3(head.x, head.y, head.z + 200.0)
    local ray = StartShapeTestRay(head.x, head.y, head.z, dest.x, dest.y, dest.z, -1, ped, 7)
    local _, hit = GetShapeTestResult(ray)
    return hit == 0
end

-- Estimate cloud cover 0..1 (fallback from rain if not available)
local function getCloudCover()
    local rain = GetRainLevel() or 0.0 -- 0..1
    return mathMin(1.0, 0.2 + rain * 0.8)
end

-- Solar gain (+°C) peaking at midday, reduced by cloud cover
local function solarGainC()
    local hour = getCurrentTime()
    local diurnal = mathMax(0.0, 1.0 - math.abs(12 - hour)/6.0) -- peak around noon
    local gain = 8.0 * diurnal * (1.0 - getCloudCover())
    return isInSun() and gain or 0.0
end

-- Wind exposure: 0 (sheltered) .. 1 (fully exposed)
local sampleDirs = {
    vector3(1,0,0), vector3(-1,0,0), vector3(0,1,0), vector3(0,-1,0),
    vector3(0.707,0.707,0), vector3(-0.707,0.707,0),
    vector3(0.707,-0.707,0), vector3(-0.707,-0.707,0)
}
local function windExposure01()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local hits = 0
    for _,d in ipairs(sampleDirs) do
        local to = pos + (d * 8.0) + vector3(0,0,1.0)
        local ray = StartShapeTestRay(pos.x, pos.y, pos.z+1.0, to.x, to.y, to.z, -1, ped, 7)
        local _, hit = GetShapeTestResult(ray)
        if hit ~= 0 then hits = hits + 1 end
    end
    local sheltered = hits / #sampleDirs
    return 1.0 - sheltered
end

-- Compute effective wind after sheltering
local function computeWindEffective()
    local w = mathMax(0.0, windSpeed or 0.0)
    local exposure = windExposure01()
    local wEff = w * (0.4 + 0.6 * exposure) -- reduce when sheltered
    return wEff, exposure
end

-- Wetness state and update (0..1)
local WET = { level = 0.0, dryRate = 0.02, rainGain = 0.08, waterGain = 0.25 }
local function updateWetness(dt)
    local ped = PlayerPedId()
    if IsEntityInWater(ped) or IsPedSwimming(ped) then
        WET.level = mathMin(1.0, WET.level + WET.waterGain*dt)
    else
        local rain = GetRainLevel() or 0.0
        if rain > 0.05 and not isInSun() then
            WET.level = mathMin(1.0, WET.level + rain*WET.rainGain*dt)
        else
            WET.level = mathMax(0.0, WET.level - WET.dryRate*dt)
        end
    end
end

-- Vehicle HVAC and greenhouse effect
local VEH = { acOn=false, setpoint=22.0, greenhouse=0.05 }
RegisterCommand("ac", function()
    VEH.acOn = not VEH.acOn
    lib.notify({ title='Vehicle A/C', description = VEH.acOn and 'A/C ON' or 'A/C OFF', type = 'inform' })
end)

local function vehicleAdjustedTemp(outdoorFeelsC)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return outdoorFeelsC end
    local veh = GetVehiclePedIsIn(ped, false)
    local engineOn = GetIsVehicleEngineRunning(veh)
    local speed = GetEntitySpeed(veh)
    if engineOn and VEH.acOn then
        local k = (speed > 5.0) and 0.3 or 0.12
        return outdoorFeelsC + (VEH.setpoint - outdoorFeelsC) * k
    end
    if isInSun() and speed < 0.5 then
        return outdoorFeelsC + VEH.greenhouse
    end
    return outdoorFeelsC
end

-- Interior thermal inertia
local INDOOR = { last=22.0, lag=0.05, bias=-1.0 }
local function interiorAdjustedTemp(outdoorFeelsC)
    local ped = PlayerPedId()
    local interior = GetInteriorFromEntity(ped)
    if interior ~= 0 then
        INDOOR.last = INDOOR.last + ( (outdoorFeelsC + INDOOR.bias) - INDOOR.last ) * INDOOR.lag
        return INDOOR.last
    else
        INDOOR.last = outdoorFeelsC
        return outdoorFeelsC
    end
end

-- Simple local heat zones (spherical)
local HeatZonesSimple = {}
RegisterNetEvent("ges:addHeatZone", function(x,y,z,radiusC,tempDeltaC)
    HeatZonesSimple[#HeatZonesSimple+1] = {pos=vector3(x,y,z), r=radiusC, dC=tempDeltaC}
end)
RegisterNetEvent("ges:clearHeatZones", function()
    HeatZonesSimple = {}
end)
local function applyHeatZones(tempC)
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local t = tempC
    for _,z in ipairs(HeatZonesSimple) do
        local d = #(p - z.pos)
        if d <= z.r then
            local w = 1.0 - (d / z.r)
            t = t + z.dC * w
        end
    end
    return t
end

-- Calculate realistic temperature based on multiple factors - optimized
local function calculateRealisticTemperature()
    -- When enabled, pull temperature directly from weather resource
    if Config.useWeatherResourceTemp and Config.weatherResource == 'renewed-weathersync' then
        currentTemperature = GlobalState.temperature or currentTemperature
        currentTemperature = addTemperatureToHistory(currentTemperature)
        dewPoint = calculateDewPoint(currentTemperature, humidity)
        feelsLikeTemperature = calculateFeelsLikeTemperature(currentTemperature, windSpeed, humidity)
        return currentTemperature
    end

    local gameWeather = getCurrentWeather()
    local currentTime = GetGameTimer() / 1000

    -- Limit update frequency for performance
    if currentTime - lastUpdateTime < 30 then
        return currentTemperature
    end

    lastUpdateTime = currentTime

    -- Get base temperature
    local baseTemperature = getSeasonalBaseTemperature()

    -- Apply modifiers
    local weatherModifier = getWeatherModifier(gameWeather)
    local timeModifier = getTimeModifier()
    local altitudeModifier = getAltitudeModifier()

    -- Calculate raw temperature
    local rawTemperature = baseTemperature + weatherModifier + timeModifier + altitudeModifier

    -- Add micro-variations for realism - simplified for performance
    rawTemperature = rawTemperature + ((mathRandom() - 0.5) * 0.5)

    -- Apply indoor modifier if player is inside
    if isIndoors then
        -- Indoor temperatures tend to be moderated
        local outdoorTemp = rawTemperature
        local idealTemp = 22 -- Ideal indoor temperature

        -- Use weighted average for indoor temperature
        rawTemperature = outdoorTemp * 0.3 + idealTemp * 0.7
    end

    -- Apply biome modifier if detected
    if biomeType == "desert" then
        -- Deserts have higher daytime temps and lower nighttime temps
        if timeOfDay == "day" then
            rawTemperature = rawTemperature + 5
        else
            rawTemperature = rawTemperature - 3
        end
    elseif biomeType == "mountain" then
        -- Mountains are generally colder
        rawTemperature = rawTemperature - 3
    elseif biomeType == "forest" then
        -- Forests have more moderate temperatures
        rawTemperature = (rawTemperature + 15) / 2
    end
    
    -- Apply water proximity effect (if near water)
    if #nearbyWaterBodies > 0 then
        -- Water has a moderating effect on temperature
        rawTemperature = rawTemperature * 0.8 + 15 * 0.2
    end
    
    -- Smooth temperature changes with weighted average
    local smoothedTemperature = addTemperatureToHistory(rawTemperature)
    currentTemperature = smoothedTemperature
    
    -- Calculate additional comfort metrics
    dewPoint = calculateDewPoint(currentTemperature, humidity)
    feelsLikeTemperature = calculateFeelsLikeTemperature(currentTemperature, windSpeed, humidity)
    
    return smoothedTemperature
end

-- Calculate dew point - optimized
function calculateDewPoint(temp, humidity)
    -- Magnus formula for dew point
    local a = 17.27
    local b = 237.7
    
    local alpha = ((a * temp) / (b + temp)) + mathLog(humidity / 100.0)
    return (b * alpha) / (a - alpha)
end

-- Calculate "feels like" temperature - optimized
function calculateFeelsLikeTemperature(temp, wind_mps, RH)
    wind_mps = wind_mps or windSpeed or 0.0
    RH = RH or humidity or 50.0
    if temp <= 10.0 and wind_mps > 1.34 then
        local V = wind_mps * 3.6 -- m/s -> km/h
        local Vp = V^0.16
        return 13.12 + 0.6215*temp - 11.37*Vp + 0.3965*temp*Vp
    elseif temp >= 27.0 and RH >= 40.0 then
        local Tf = temp * 9/5 + 32.0
        local HI = -42.379 + 2.04901523*Tf + 10.14333127*RH
                  - 0.22475541*Tf*RH - 6.83783e-3*(Tf*Tf)
                  - 5.481717e-2*(RH*RH) + 1.22874e-3*(Tf*Tf)*RH
                  + 8.5282e-4*Tf*(RH*RH) - 1.99e-6*(Tf*Tf)*(RH*RH)
        return (HI - 32.0) * 5.0/9.0
    else
        return temp
    end
end
-- Optimized function to check for nearby heat sources
function isNearHeatSource()
    if not Config.useHeatzone then
        return false
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- First check active zones which is more efficient
    for _, zoneData in pairs(Zones) do
        if zoneData.zone and zoneData.zone:isPointInside(playerCoords) then
            return true
        end
    end
    
    -- Check for heat source entities in the game world
    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        if GetEntityModel(obj) == GetHashKey(Config.CampfireModel) then
            local objCoords = GetEntityCoords(obj)
            local dist = #(playerCoords - objCoords)
            if dist <= Config.Cold.heatSourceRange then
                return true
            end
        end
    end
    
    -- Return false if no heat source found
    return false
end

-- Current weather retrieval optimization
function getCurrentWeather()
    if Config.weatherResource == 'renewed-weathersync' then
        return GlobalState.weather and GlobalState.weather.weather or "clear"
    elseif Framework == 'esx' and exports['esx_weather'] then
        return exports['esx_weather']:getCurrentWeather() or "clear"
    elseif Framework == 'qbox' and exports['qb-weathersync'] then
        return exports['qb-weathersync']:GetWeather() or "clear"
    else
        return string.lower(GetPrevWeatherTypeHashName() or "CLEAR")
    end
end

function getCurrentTime()
    local timeInHours
    if Config.weatherResource == 'renewed-weathersync' then
        local timeData = GlobalState.currentTime
        if timeData and timeData.hour and timeData.minute then
            timeInHours = timeData.hour + (timeData.minute / 60)
        else
            timeInHours = 12 -- Default to 12:00
        end
    else
        timeInHours = GetClockHours() + (GetClockMinutes() / 60)
    end
    return mathFloor(timeInHours) % 24
end

-- Detect biome type based on coordinates and ground hash
function detectBiomeType(coords)
    -- Get ground hash at player position
    local success, groundHash = GetHashOfMapAreaAtCoords(coords.x, coords.y, coords.z)
    
    -- Check for desert areas (sandy ground)
    if coords.x >= 1000.0 and coords.x <= 4000.0 and 
       coords.y >= 2000.0 and coords.y <= 4000.0 then
        return "desert"
    -- Check for mountain areas (high altitude)
    elseif coords.z > 400.0 then
        return "mountain"
    -- Check for forest areas (vegetation check)
    elseif coords.y <= -1000.0 or (coords.x <= -1500.0 and coords.y <= 3000.0) then
        return "forest"
    end
    
    return "default"
end

-- Get perceived temperature including wind chill and heat index - optimized
-- Get perceived temperature including microclimate & vehicle/interior
function getPerceivedTemperature()
    local actualTemperature = calculateRealisticTemperature()

    -- Effective wind based on shelter
    local windEff, exposure = computeWindEffective()
    local shadeAdj = solarGainC()
    local wetPenalty = 4.0 * WET.level

    -- Base physiological feels (uses windEff for WCT)
    local baseFeels = calculateFeelsLikeTemperature(actualTemperature, windEff, humidity)

    -- Track factors for export/event (positive deltas)
    lastWindChill = 0.0
    lastHeatIndex = 0.0
    if actualTemperature <= 10.0 and windEff > 1.34 then
        local V = windEff * 3.6
        local Vp = V^0.16
        local wc = 13.12 + 0.6215*actualTemperature - 11.37*Vp + 0.3965*actualTemperature*Vp
        lastWindChill = mathMax(0.0, actualTemperature - wc)
    elseif actualTemperature >= 27.0 and humidity >= 40.0 then
        local Tf = actualTemperature * 9/5 + 32.0
        local RH = humidity
        local HI = -42.379 + 2.04901523*Tf + 10.14333127*RH
                  - 0.22475541*Tf*RH - 6.83783e-3*(Tf*Tf)
                  - 5.481717e-2*(RH*RH) + 1.22874e-3*(Tf*Tf)*RH
                  + 8.5282e-4*Tf*(RH*RH) - 1.99e-6*(Tf*Tf)*(RH*RH)
        local HIc = (HI - 32.0) * 5.0/9.0
        lastHeatIndex = mathMax(0.0, HIc - actualTemperature)
    end

    -- Micro adjustments: sun & wetness
    local feels = baseFeels + shadeAdj - wetPenalty

    -- Vehicle & interior & local heat zones
    feels = vehicleAdjustedTemp(feels)
    feels = interiorAdjustedTemp(feels)
    feels = applyHeatZones(feels)

    -- Save globals for UI/exports
    feelsLikeTemperature = feels
    windExposure = exposure
    lastWindEff = windEff
    lastInSun = isInSun()
    lastWet = WET.level

    return feels
end

-- Function to create a heat zone
function createHeatZone(coords, id)
    if not Config.useHeatzone then return end
    -- Validate parameters
    if not coords or not id then return end

    local zoneName = tostring(id)
    if Zones[zoneName] then return end

    Zones[zoneName] = {
        id = id,
        coords = coords,
        radius = Config.HeatZone.radius or 2.0,
        inside = false
    }
end

function deleteHeatZone(zoneName)
    if not Config.useHeatzone then return end
    if Zones[zoneName] then
        Zones[zoneName] = nil
    end
end

-- Monitor player proximity to heat zones
Citizen.CreateThread(function()
    while true do
        if Config.useHeatzone then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, data in pairs(Zones) do
                local distance = #(playerCoords - data.coords)
                if distance <= data.radius then
                    if not data.inside then
                        data.inside = true
                        notify('Heat Source', 'You feel the warmth from the heat source.')
                    end
                elseif data.inside then
                    data.inside = false
                    notify('Heat Source', 'You left the warmth of the heat source.')
                end
            end
        end

        Wait(500)
    end
end)

-- Optimize detection of nearby water bodies
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Clear previous water bodies
        nearbyWaterBodies = {}
        
        -- Check for water in cardinal directions with reduced number of checks
        local checkDistance = 50.0
        local directions = {
            {1, 0}, {-1, 0}, {0, 1}, {0, -1}
        }
        
        for _, dir in ipairs(directions) do
            local checkPoint = vector3(
                playerCoords.x + dir[1] * checkDistance,
                playerCoords.y + dir[2] * checkDistance,
                playerCoords.z
            )
            
            local waterHeight = GetWaterHeight(checkPoint.x, checkPoint.y, checkPoint.z)
            if waterHeight and waterHeight > -1000.0 then
                table.insert(nearbyWaterBodies, {
                    coords = vector3(checkPoint.x, checkPoint.y, waterHeight),
                    distance = #(playerCoords - vector3(checkPoint.x, checkPoint.y, waterHeight))
                })
                break -- Exit early if water found
            end
        end
        
        -- Detect biome type based on ground vegetation and location
        biomeType = detectBiomeType(playerCoords)
        
        -- Update roof state (indoors check)
        isIndoors = GetRoofState()
        
        -- Update less frequently for performance
        Wait(30000) -- Check every 30 seconds
    end
end)

-- Wetness update thread (1s tick)
Citizen.CreateThread(function()
    local prev = GetGameTimer()
    while true do
        local now = GetGameTimer()
        local dt = (now - prev)/1000.0; prev = now
        updateWetness(dt)
        Wait(1000)
    end
end)

-- Temperature update thread with optimized update frequency
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Adaptive update frequency - update more frequently when temperature is changing rapidly
        local updateInterval = 10000 -- Default: 10 seconds
        local tempDelta = 0
        
        if #temperatureHistory >= 2 then
            tempDelta = mathAbs(temperatureHistory[1] - temperatureHistory[2])
            if tempDelta > 3 then
                updateInterval = 5000 -- More frequent updates during rapid changes
            elseif tempDelta < 0.5 then
                updateInterval = 15000 -- Less frequent updates during stable conditions
            end
        end
        
        -- Update perceived temperature
        local perceivedTemperature = getPerceivedTemperature()
        
        -- Trigger temperature update event for other resources to use
        TriggerEvent('weather-temperature:update', {
            temperature = currentTemperature,
            perceived = perceivedTemperature,
            feelsLike = feelsLikeTemperature,
            windChill = lastWindChill,
            heatIndex = lastHeatIndex,
            weather = getCurrentWeather(),
            season = getCurrentSeason(),
            timeOfDay = timeOfDay,
            humidity = humidity,
            windSpeed = lastWindEff or windSpeed,
            dewPoint = dewPoint,
            isIndoors = isIndoors,
            biome = biomeType,
            sun = lastInSun or false,
            windExposure = windExposure or 1.0,
            wetness = lastWet or 0.0
        })
        
        Wait(updateInterval)
    end
end)

-- Export functions for other scripts to use
function getTemperatureData()
    local actualTemp = calculateRealisticTemperature()
    local perceivedTemp = getPerceivedTemperature()
    local windChill = lastWindChill or 0.0
    local heatIndexVal = lastHeatIndex or 0.0
    local weather = getCurrentWeather()
    local season = getCurrentSeason()
    
    return {
        temperature = actualTemp,
        perceived = perceivedTemp,
        feelsLike = feelsLikeTemperature,
        windChill = windChill,
        heatIndex = heatIndexVal,
        weather = weather,
        season = season,
        timeOfDay = timeOfDay,
        humidity = humidity,
        windSpeed = lastWindEff or windSpeed,
        dewPoint = dewPoint,
        isIndoors = isIndoors,
        biome = biomeType,
        clothingInsulation = getClothingInsulation(),
        sun = lastInSun or false,
        windExposure = windExposure or 1.0,
        wetness = lastWet or 0.0
    }
end

-- Export the function so other scripts can call it
exports("getTemperatureData", getTemperatureData)

-- Register command to check temperature
RegisterCommand('checktemp', function()
    local data = getTemperatureData()
    notify('Temperature', string.format('Current: %.1f°C | Feels like: %.1f°C',
        data.temperature, data.feelsLike))
end, false)

-- Event handler for temperature updates from server
RegisterNetEvent('weather-temperature:syncData')
AddEventHandler('weather-temperature:syncData', function(data)
    if data.temperature then currentTemperature = data.temperature end
    if data.windSpeed then windSpeed = data.windSpeed end
    if data.humidity then humidity = data.humidity end
end)

print('Weather and temperature system initialized')






