TempConfig = {
  TickMs = 2000,                 -- คำนวณ/ส่งทุก 2 วินาที
  VeryCold =  -10.0,
  Cold     =    0.0,
  Hot      =   35.0,
  UsePseudoWeatherIfMissing = true,   -- ไม่มีแหล่งข้อมูลอากาศภายนอก ให้คำนวณคร่าว ๆ เอง
  Debug = (GetConvarInt('ges_debug', 0) == 1)
}
