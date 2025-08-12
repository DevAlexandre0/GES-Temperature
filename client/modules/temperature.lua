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
        Citizen.Wait(5000)
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
end


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
            
            local found, waterHeight = GetWaterHeight(checkPoint.x, checkPoint.y, checkPoint.z)
            if found and waterHeight and waterHeight > -1000.0 then
                local waterCoords = vector3(checkPoint.x, checkPoint.y, waterHeight)
                local distance = #(playerCoords - waterCoords)
                table.insert(nearbyWaterBodies, {
                    coords = waterCoords,
                    distance = distance
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



CreateThread(function()
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
            
            local found, waterHeight = GetWaterHeight(checkPoint.x, checkPoint.y, checkPoint.z)
            if found and waterHeight and waterHeight > -1000.0 then
                local waterCoords = vector3(checkPoint.x, checkPoint.y, waterHeight)
                local distance = #(playerCoords - waterCoords)
                table.insert(nearbyWaterBodies, {
                    coords = waterCoords,
                    distance = distance
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

