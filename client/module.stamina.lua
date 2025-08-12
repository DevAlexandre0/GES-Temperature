-- Stamina module: จัดการหมดแรง/ฟื้นแรงแบบเบาเครื่อง

local st = { value = 100.0, exhausted = false, last = GetGameTimer() }
local DEBUG = StamConfig.Debug
local function dbg(msg) if DEBUG then print(('^6[GES-Stam]^7 %s'):format(msg)) end end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

local function isSprinting()
  local ped = PlayerPedId()
  return IsPedRunning(ped) or IsPedSprinting(ped)
end

CreateThread(function()
  while true do
    Wait(StamConfig.TickMs)
    local dt = StamConfig.TickMs / 1000.0
    local delta = 0.0

    if isSprinting() then
      delta = -StamConfig.DrainSprint * dt
    else
      local ped = PlayerPedId()
      if IsPedWalking(ped) then delta = StamConfig.RegenWalk * dt
      else delta = StamConfig.RegenIdle * dt end
    end

    local prev = st.value
    st.value = clamp(prev + delta, StamConfig.ClampMin, StamConfig.ClampMax)
    if math.abs(st.value - prev) >= 0.5 then
      st.last = GetGameTimer()
      if DEBUG then dbg(('stam=%.1f'):format(st.value)) end
      -- ไม่จำเป็นต้องส่งทุกครั้ง (ลดเน็ต) — ถ้าจะใช้ HUD ค่อย export ไปเรียกดึงเอง
    end

    if (not st.exhausted) and st.value <= StamConfig.ExhaustedThreshold then
      st.exhausted = true
      TriggerEvent('ges:stamina:exhausted', { durationMs = StamConfig.ExhaustBlackoutMs })
      if DEBUG then dbg('EXHAUSTED!') end
    elseif st.exhausted and st.value > StamConfig.ExhaustedThreshold + 10.0 then
      st.exhausted = false
      if DEBUG then dbg('recovered') end
    end
  end
end)

local function getStaminaData() return st end
exports('getStaminaData', getStaminaData)
