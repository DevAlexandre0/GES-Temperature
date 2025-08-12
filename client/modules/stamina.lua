-- Module: Stamina (non-destructive)
local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(...) if DEBUG then print(('^6[GES-Stam]^7 '..string.format(...))) end

local function pullLegacyStamina()
  if type(getStaminaData) == 'function' then
    local ok, t = pcall(getStaminaData)
    if ok and type(t)=='table' then return t end
  end
  return nil
end

local st = { value = 100.0, exhausted = false, last = GetGameTimer() }
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function isSprinting()
  local ped = PlayerPedId()
  return IsPedRunning(ped) or IsPedSprinting(ped)
end

CreateThread(function()
  while true do
    Wait(200)
    local legacy = pullLegacyStamina()
    if legacy then
      -- ถ้า legacy แจ้งผลหมดแรงเอง ก็ไม่ต้องซ้ำ
      if DEBUG and legacy.value then dbg('legacy stamina → %.1f', legacy.value) end
    else
      -- fallback เบา ๆ
      local dt = 0.2
      local delta = 0.0
      if isSprinting() then delta = -8.0*dt
      elseif IsPedWalking(PlayerPedId()) then delta = 4.0*dt
      else delta = 10.0*dt end

      local prev = st.value
      st.value = clamp(prev + delta, 0.0, 100.0)
      if not st.exhausted and st.value <= 5.0 then
        st.exhausted = true
        TriggerEvent('ges:stamina:exhausted', { durationMs = 350 })
        if DEBUG then dbg('fallback exhausted!') end
      elseif st.exhausted and st.value > 15.0 then
        st.exhausted = false
      end
      -- (ไม่ส่งค่า update บ่อยเพื่อลดเน็ต ถ้าต้องใช้ HUD ให้ exports ไปดึงเอง)
    end
  end
end)

exports('getStaminaData', function()
  return pullLegacyStamina() or st
end)
