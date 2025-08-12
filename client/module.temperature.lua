-- Temperature module: คำนวณค่า feels-like + band แล้วแจ้ง SurvCore/Server

local data = { temperature = 20.0, feelsLike = 20.0, weather = 'clear', windSpeed = 1.0, humidity = 50, last = 0 }
local DEBUG = TempConfig.Debug

local function dbg(msg) if DEBUG then print(('^2[GES-Temp]^7 %s'):format(msg)) end end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

-- ตัวอย่าง pseudo weather (ใช้เมื่อไม่มีระบบอากาศภายนอก)
local weatherOptions = { 'CLEAR','CLOUDS','OVERCAST','RAIN','THUNDER','FOGGY','SNOW','BLIZZARD' }
local function pseudoWeather()
  return weatherOptions[ (GetGameTimer() // 30000) % #weatherOptions + 1 ]
end

local function getRawTemperature()
  -- ที่นี่คุณสามารถผูกกับระบบอากาศจริงได้ เช่น exports อื่น
  -- ถ้าไม่มี → ใช้ pseudo
  local w = pseudoWeather()
  local base
  if w == 'BLIZZARD' or w == 'SNOW' then base = math.random(-15, -5)
  elseif w == 'RAIN' or w == 'FOGGY' then base = math.random(5, 15)
  else base = math.random(15, 28) end
  return base, w
end

local function computeFeelsLike(tempC, wind)
  -- simplified wind-chill
  wind = wind or 1.0
  return tempC - (wind * 0.6)
end

CreateThread(function()
  while true do
    Wait(TempConfig.TickMs)
    local t, w = getRawTemperature()
    data.temperature = t
    data.windSpeed = 1.0 + (GetWindSpeed() or 0.0)
    data.humidity  = 45 + (math.random(-10,10))
    data.feelsLike = computeFeelsLike(t, data.windSpeed)
    data.weather   = w
    data.last = GetGameTimer()

    local band = 'normal'
    if data.feelsLike <= TempConfig.Cold then band = 'cold' end
    if data.feelsLike >= TempConfig.Hot  then band = 'hot'  end

    if DEBUG then dbg(('T=%.1f, feels=%.1f, band=%s'):format(data.temperature, data.feelsLike, band)) end

    -- แจ้ง (client) ให้ SurvCore รับไป relay (หรือ main.lua จะส่งตรงถ้าไม่มี SurvCore)
    TriggerEvent('ges:temperature:update', {
      celsius   = data.feelsLike,
      band      = band,
      weather   = data.weather,
      windSpeed = data.windSpeed,
      humidity  = data.humidity
    })
  end
end)

-- Export ให้สคริปต์อื่นอ่านได้
local function getTemperatureData() return data end
exports('getTemperatureData', getTemperatureData)
