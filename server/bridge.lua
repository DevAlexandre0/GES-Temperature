local DEBUG = (GetConvarInt('ges_debug', 0) == 1)
local function dbg(msg) if DEBUG then print(('^3[GES-Temp/SVR]^7 %s'):format(msg)) end end

AddEventHandler('onResourceStart', function(res)
  if res == GetCurrentResourceName() then dbg('started') end
end)
