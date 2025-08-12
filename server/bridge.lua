local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(msg) if DEBUG then print(('^3[GES-Temp/SVR]^7 %s'):format(msg)) end end

AddEventHandler('onResourceStart', function(res)
  if res == GetCurrentResourceName() then dbg('started') end
end)

-- store last reported stats per player
local lastTemp, lastWet, lastStam = {}, {}, {}

RegisterNetEvent('ges:temperature:changed', function(data)
  lastTemp[source] = data
  dbg(('temp update from %d'):format(source))
end)

RegisterNetEvent('ges:wetness:changed', function(data)
  lastWet[source] = data
  dbg(('wetness update from %d'):format(source))
end)

RegisterNetEvent('ges:stamina:changed', function(data)
  lastStam[source] = data
end)

RegisterNetEvent('ges:stamina:exhausted', function(payload)
  dbg(('stamina exhausted from %d'):format(source))
end)

exports('getTemperatureData', function(id)
  return id and lastTemp[id] or lastTemp
end)

exports('getWetnessData', function(id)
  return id and lastWet[id] or lastWet
end)

exports('getStaminaData', function(id)
  return id and lastStam[id] or lastStam
end)
