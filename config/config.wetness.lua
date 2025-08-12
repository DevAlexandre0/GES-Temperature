WetConfig = {
  TickMs    = 1000,
  DryRate   = 0.8,    -- %/s บนบก + ไม่ฝน
  RainGain  = 2.5,    -- %/s ฝนตก
  WaterGain = 8.0,    -- %/s อยู่/เพิ่งขึ้นจากน้ำ
  ClampMin  = 0.0, ClampMax = 100.0,
  Debug = (GetConvarInt('ges_debug', 0) == 1)
}
