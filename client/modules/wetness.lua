-- Module: Wetness (non-destructive)
local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(...) if DEBUG then print(('^5[GES-Wet]^7 '..string.format(...))) end

-- ลองดูว่ามีฟังก์ชัน/ตัวแปรเดิมไหม
local function pullLegacyWetness()
  if type(getWetnessData) == 'function' then
    local ok, t = pcall(getWetnessData)
    if ok and type(t)=='table' then return t end
  end
  return nil
end

-- fallback เบา ๆ ถ้าไม่มีของเดิม
local lvl, rain, submerged = 0.0, 0, 0
local function isRaining()
  local rl = GetRainLevel() or 0.0
  return rl > 0.01
end
local function inWater()
  local ped = PlayerPedId()
  return IsPedSwimming(ped) or IsEntityInWater(ped)
end

CreateThread(function()
  while true do
    Wait(1000)
    local legacy = pullLegacyWetness()
    if legacy then
      TriggerEvent('ges:wetness:update', legacy)
      if DEBUG then dbg('legacy wetness → level=%.1f', legacy.level or -1) end
    else
      -- minimal fallback (ไม่ไปรบกวนระบบเดิม)
      local dt = 1.0
      rain = isRaining() and 1 or 0
      submerged = inWater() and 1 or 0
      local gain = 0.0
      if submerged == 1 then gain = 8.0*dt
      elseif rain == 1 then gain = 2.5*dt
      else gain = -0.8*dt end
      lvl = math.max(0.0, math.min(100.0, lvl + gain))
      TriggerEvent('ges:wetness:update', { level = lvl, rain = rain, submerged = submerged })
      if DEBUG then dbg('fallback wetness → level=%.1f', lvl) end
    end
  end
end)

exports('getWetnessData', function()
  return pullLegacyWetness() or { level = lvl, rain = rain, submerged = submerged }
end)
