local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(...) if DEBUG then print(('^3[GES-Temp/Bridge]^7 '..string.format(...))) end
local function hasSurvCore() return GetResourceState('GES-SurvCore') == 'started' end

-- ถ้า SurvCore รันอยู่: เราจะปล่อยให้มันรับ client event ไป relay เอง
-- ถ้าไม่รัน: เราจะ relay ขึ้น server ตรง เพื่อไม่ให้ข้อมูลเงียบ

AddEventHandler('ges:temperature:update', function(data)
  if hasSurvCore() then dbg('temp:update → SurvCore'); return end
  TriggerServerEvent('ges:temperature:changed', data)
end)

AddEventHandler('ges:wetness:update', function(data)
  if hasSurvCore() then dbg('wet:update → SurvCore'); return end
  TriggerServerEvent('ges:wetness:changed', data)
end)

AddEventHandler('ges:stamina:update', function(data)
  if hasSurvCore() then dbg('stamina:update → SurvCore'); return end
  TriggerServerEvent('ges:stamina:changed', data)
end)

AddEventHandler('ges:stamina:exhausted', function(payload)
  if hasSurvCore() then dbg('stamina:exhausted → SurvCore'); return end
  TriggerServerEvent('ges:stamina:exhausted', payload or {})
end)
