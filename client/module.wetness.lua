-- Wetness module: ติดตามความเปียกจากฝน/น้ำ

local wet = { level = 0.0, rain = 0, submerged = 0, last = 0 }
local DEBUG = WetConfig.Debug
local function dbg(msg) if DEBUG then print(('^5[GES-Wet]^7 %s'):format(msg)) end end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

local function isRaining()
  local rainLvl = GetRainLevel() or 0.0
  return rainLvl > 0.01
end

local function inWater()
  local ped = PlayerPedId()
  return IsPedSwimming(ped) or IsEntityInWater(ped)
end

CreateThread(function()
  while true do
    Wait(WetConfig.TickMs)
    local dt = WetConfig.TickMs / 1000.0
    local gain = 0.0

    wet.rain = isRaining() and 1 or 0
    wet.submerged = inWater() and 1 or 0

    if wet.submerged == 1 then
      gain = WetConfig.WaterGain * dt
    elseif wet.rain == 1 then
      gain = WetConfig.RainGain * dt
    else
      gain = -WetConfig.DryRate * dt
    end

    local prev = wet.level
    wet.level = clamp(prev + gain, WetConfig.ClampMin, WetConfig.ClampMax)
    wet.last  = GetGameTimer()

    if DEBUG and math.abs(wet.level - prev) >= 1.0 then dbg(('wet=%.1f rain=%d water=%d'):format(wet.level, wet.rain, wet.submerged)) end

    TriggerEvent('ges:wetness:update', { level = wet.level, rain = wet.rain, submerged = wet.submerged })
  end
end)

local function getWetnessData() return wet end
exports('getWetnessData', getWetnessData)
