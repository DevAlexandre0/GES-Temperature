CreateThread(function()
    local prev = GetGameTimer()
    while true do
        local now = GetGameTimer()
        local dt = (now - prev)/1000.0; prev = now
        updateWetness(dt)
        Wait(1000)
    end
end)

