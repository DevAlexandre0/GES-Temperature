StamConfig = {
  TickMs = 200,
  DrainSprint = 8.0,      -- %/s ตอนสปรินต์
  RegenIdle  = 10.0,      -- %/s ตอนยืนนิ่ง
  RegenWalk  = 4.0,       -- %/s ตอนเดิน
  ExhaustedThreshold = 5.0,
  ExhaustBlackoutMs = 350,
  ClampMin = 0.0, ClampMax = 100.0,
  Debug = (GetConvarInt('ges_debug', 0) == 1)
}
