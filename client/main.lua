local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function hasSurvCore()
  return GetResourceState('GES-SurvCore') == 'started'
end
local function dbg(msg) if DEBUG then print(('^3[GES-Temp/Bridge]^7 %s'):format(msg)) end end

-- Relay helper: ถ้า SurvCore ไม่รัน → ยิงขึ้น server ตรง
AddEventHandler('ges:temperature:update', function(data)
  if hasSurvCore() then
    dbg('temperature:update → SurvCore listening (no direct relay)')
    return
  end
  TriggerServerEvent('ges:temperature:changed', data)
end)

AddEventHandler('ges:wetness:update', function(data)
  if hasSurvCore() then
    dbg('wetness:update → SurvCore listening (no direct relay)')
    return
  end
  TriggerServerEvent('ges:wetness:changed', data)
end)

AddEventHandler('ges:stamina:exhausted', function(payload)
  if hasSurvCore() then
    dbg('stamina:exhausted → SurvCore listening (no direct relay)')
    return
  end
  TriggerServerEvent('ges:stamina:exhausted', payload or {})
end)
