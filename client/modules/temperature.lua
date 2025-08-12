local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords

CreateThread(function()
    local lastLabel = "none"
    while true do
        local feels = feelsLikeTemperature ~= 0 and feelsLikeTemperature or getPerceivedTemperature()
        local clo = getClothingInsulation()
        local label, sev = computeThermalRisk(feels, humidity or 50, lastWindEff or windSpeed or 0.0, isIndoors, clo, (WET and WET.level) or 0.0)
        currentRisk = label
        riskSeverity = sev
        applyFrameworkStatusDrains(sev)
        if sev >= 2 then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1 * sev)
        end
        if label ~= lastLabel then
            notify('Thermal Risk', string.format('%s (sev %d)', label, sev))
            lastLabel = label
        end
        Wait(5000)
    end
end)

CreateThread(function()
    while Config.useHeatzone do
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
        Wait(500)
    end
end)

-- Optimize detection of nearby water bodies
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        nearbyWaterBodies = {}

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

            local found, waterHeight = GetWaterHeight(checkPoint.x, checkPoint.y, checkPoint.z)
            if found and waterHeight and waterHeight > -1000.0 then
                local waterCoords = vector3(checkPoint.x, checkPoint.y, waterHeight)
                local distance = #(playerCoords - waterCoords)
                nearbyWaterBodies[#nearbyWaterBodies+1] = {
                    coords = waterCoords,
                    distance = distance
                }
                break -- Exit early if water found
            end
        end

        biomeType = detectBiomeType(playerCoords)
        isIndoors = GetRoofState()

        Wait(30000) -- Check every 30 seconds
    end
end)

