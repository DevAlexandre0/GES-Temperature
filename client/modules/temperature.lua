-- Module: Temperature (non-destructive)
local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(...) if DEBUG then print(('^2[GES-Temp]^7 '..string.format(...))) end

-- helper: หาแหล่ง temp เดิม
local function pullLegacyData()
  -- 1) ถ้ามีฟังก์ชัน global ใน client.lua เดิม
  if type(getTemperatureData) == 'function' then
    local ok, t = pcall(getTemperatureData)
    if ok and type(t) == 'table' then return t end
  end
  -- 2) ถ้ามี export ตั้งชื่อ resource (เช่น weather-temperature หรือ GES-Temperature)
  for _,res in ipairs({ 'GES-Temperature', 'weather-temperature' }) do
    if GetResourceState(res) == 'started' and exports[res] and exports[res].getTemperatureData then
      local ok, t = pcall(function() return exports[res]:getTemperatureData() end)
      if ok and type(t) == 'table' then return t end
    end
  end
  return nil
end

-- band ช่วง (ปรับได้ด้วย convar ถ้าต้องการ)
local COLD = tonumber(GetConvar('ges_temp_cold','0')) or 0
local HOT  = tonumber(GetConvar('ges_temp_hot','35')) or 35
local function bandOf(c) if c <= COLD then return 'cold' elseif c >= HOT then return 'hot' else return 'normal' end end

CreateThread(function()
  while true do
    Wait(2000)
    local t = pullLegacyData()
    if t then
      local feels = t.feelsLike or t.temperature or 0.0
      local payload = {
        celsius   = feels,
        band      = bandOf(feels),
        weather   = t.weather,
        windSpeed = t.windSpeed,
        humidity  = t.humidity
      }
      TriggerEvent('ges:temperature:update', payload)
      if DEBUG then dbg('legacy export → band=%s (%.1f°C)', payload.band, feels) end
    else
      -- ไม่มีแหล่งข้อมูลเดิม → ไม่ส่งอะไร เพื่อลดการชนกับ client.lua เดิม
      -- (ถ้าอยากมี fallback pseudo ที่นี่ ก็บอกได้ เดี๋ยวผมเติมให้)
    end
  end
end)

-- re-expose export ให้เข้ากับ HUD/สคริปต์อื่น ถ้าต้องการ
exports('getTemperatureData', function()
  return pullLegacyData() -- คืนตามของเดิม (ไม่ทับ)
end)
