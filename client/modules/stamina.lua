CreateThread(function()
    local stamina = 100.0
    local exhaustedClip = 'move_m@injured'
    local clipLoaded = false
    local clipApplied = false
    while true do
        local player = PlayerId()
        local playerPed = PlayerPedId()
        local data = getTemperatureData()
        local risk = data.riskSeverity or 0
        local feels = data.feelsLike or 0.0
        local envMult = 1.0
        if Config.Stamina and Config.Stamina.TempModifiers then
            for _, cfg in ipairs(Config.Stamina.TempModifiers) do
                if risk >= cfg.threshold then
                    envMult = cfg.multiplier
                end
            end
        end
        if feels <= 0.0 or feels >= 32.0 then
            envMult = envMult * 0.85
        end
        if IsPedJumping(playerPed) or IsPedClimbing(playerPed) or IsPedInMeleeCombat(playerPed) then
            stamina = stamina - (2.5 * envMult)
        else
            stamina = stamina + (1.5 * envMult)
        end
        stamina = mathMax(0.0, mathMin(100.0, stamina))
        if stamina <= 10.0 and not clipApplied then
            if not clipLoaded then
                RequestAnimSet(exhaustedClip)
                while not HasAnimSetLoaded(exhaustedClip) do Citizen.Wait(0) end
                clipLoaded = true
            end
            SetPedMovementClipset(playerPed, exhaustedClip, 1.0)
            clipApplied = true
        elseif stamina > 10.0 and clipApplied then
            ResetPedMovementClipset(playerPed, 0.0)
            clipApplied = false
        end
        SetPlayerStamina(player, stamina)
        Citizen.Wait(500)
    end
end)

