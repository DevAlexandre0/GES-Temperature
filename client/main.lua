local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(...)
    if DEBUG then
        print(('^3[GES-Temp/Bridge]^7 ' .. string.format(...)))
    end
end

-- signal that modular threads are loaded
GES_T_MODULAR = true

local function hasSurvCore()
    return GetResourceState('GES-SurvCore') == 'started'
end

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

function notify(title, message)
    if resourceStarted('ox_lib') and lib and lib.notify then
        lib.notify({ title = title or 'Info', description = message or '' })
    else
        TriggerEvent('chat:addMessage', { args = { title or 'Info', message or '' } })
    end
end

function applyFrameworkStatusDrains(severity)
    if severity <= 0 then return end
    local thirstDrain = severity * 100
    local hungerDrain = math.floor(severity * 60)
    if resourceStarted('esx_status') then
        TriggerEvent('esx_status:remove', 'thirst', thirstDrain)
        TriggerEvent('esx_status:remove', 'hunger', hungerDrain)
    elseif resourceStarted('qb-core') then
        TriggerEvent('ges:thermal:status', { thirst = thirstDrain, hunger = hungerDrain, severity = severity })
    end
end

-- bridge events to server when SurvCore is absent
AddEventHandler('ges:temperature:update', function(data)
    if hasSurvCore() then
        dbg('temp:update → SurvCore')
        return
    end
    TriggerServerEvent('ges:temperature:changed', data)
end)

AddEventHandler('ges:wetness:update', function(data)
    if hasSurvCore() then
        dbg('wet:update → SurvCore')
        return
    end
    TriggerServerEvent('ges:wetness:changed', data)
end)

AddEventHandler('ges:stamina:update', function(data)
    if hasSurvCore() then
        dbg('stamina:update → SurvCore')
        return
    end
    TriggerServerEvent('ges:stamina:changed', data)
end)

AddEventHandler('ges:stamina:exhausted', function(payload)
    if hasSurvCore() then
        dbg('stamina:exhausted → SurvCore')
        return
    end
    TriggerServerEvent('ges:stamina:exhausted', payload or {})
end)
