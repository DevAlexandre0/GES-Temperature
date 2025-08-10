Config = Config or {}

-- Default configuration values␊
Config.useHeatzone = true -- Enable creation and detection of heat zones
Config.weatherResource = 'renewed-weathersync' -- 'wethersync', 'renewed-weathersync', or 'custom'␊
Config.useWeatherResourceTemp = false -- Set to true to use weather resource temperature directly
Config.Framework = 'standalone' -- Options: 'esx', 'qbox', 'standalone'
Config.Debug = false -- Set to true to enable debug mode

-- Temperature thresholds and effects
Config.Cold = {
    coldThreshold = 5,           -- Temperature where cold effects begin (5°C)
    hypothermiaThreshold = -10,  -- Temperature where hypothermia risk starts (-10°C)
    tickInterval = 10000,        -- Time in milliseconds between cold status checks
    staminaPenalty = 10,         -- Stamina penalty per tick
    healthPenalty = 5,           -- Health penalty per tick at hypothermia level
    speedPenalty = 0.9,          -- Movement speed reduction when cold
    heatSourceRange = 10.0       -- Range to detect heat sources
}

-- Heat zone configuration
Config.HeatZone = { 
    radius = 10.0,
    heat = 500,
    tick = 1000
}

-- Enhanced weather configuration
Config.EnhancedWeather = {
    Enabled = true,
    
    -- Temperature update frequency in milliseconds
    UpdateFrequency = 10000,
    
    -- Biome temperature modifiers
    BiomeModifiers = {
        desert = {
            dayModifier = 5.0,    -- Hotter during the day
            nightModifier = -3.0  -- Colder at night
        },
        mountain = {
            dayModifier = -3.0,   -- Colder during the day
            nightModifier = -5.0  -- Much colder at night
        },
        forest = {
            dayModifier = -1.0,   -- Slightly cooler during the day
            nightModifier = -2.0  -- Cooler at night
        },
        default = {
            dayModifier = 0.0,
            nightModifier = 0.0
        }
    },
    
    -- Clothing insulation values (percentage of cold reduction)
    ClothingInsulation = {
        lightJacket = 20,
        mediumJacket = 35,
        heavyJacket = 50,
        winterCoat = 70
    },
    
    -- Indoor temperature settings
    Indoor = {
        baseTemperature = 22,     -- Base indoor temperature
        outdoorInfluence = 0.3    -- How much outdoor temperature affects indoors (0-1)
    },
    
    -- Humidity settings
    Humidity = {
        desert = {min = 10, max = 30},
        mountain = {min = 30, max = 60},
        forest = {min = 50, max = 80},
        default = {min = 40, max = 70}
    },
    
    -- Wind settings
    Wind = {
        baseSpeed = {
            clear = 0.5,
            clouds = 1.0,
            overcast = 1.2,
            foggy = 1.0,
            rain = 2.0,
            thunder = 3.5,
            snow = 1.5,
            blizzard = 4.0
        },
        variation = {
            clear = 0.5,
            clouds = 0.5,
            overcast = 0.7,
            foggy = 0.5,
            rain = 1.0,
            thunder = 1.5,
            snow = 0.8,
            blizzard = 1.5
        },
        -- Time-based multipliers
        timeMultipliers = {
            morning = 0.8,    -- 5-9 AM
            midday = 1.2,     -- 10-16
            evening = 1.0,    -- 17-21
            night = 0.7       -- 22-4
        }
    },
    
    -- Sunrise and sunset times (24-hour format)
    SunriseSunset = {
        spring = {sunrise = 6, sunset = 19},
        summer = {sunrise = 5, sunset = 21},
        autumn = {sunrise = 7, sunset = 18},
        winter = {sunrise = 8, sunset = 16}
    }
}

-- Enhanced cold effects configuration
Config.EnhancedCold = {
    -- Visual effects
    VisualEffects = {
        mild = {
            modifier = "rply_saturation_neg",
            strength = 0.3
        },
        moderate = {
            modifier = "rply_vignette",
            strength = 0.5
        },
        severe = {
            modifier = "rply_vignette_fog",
            strength = 0.7
        },
        extreme = {
            modifier = "death_water",
            strength = 0.4
        }
    },
    
    -- Movement effects
    MovementEffects = {
        mild = {
            animSet = "move_m@drunk@slightlydrunk",
            speedPenalty = 0.1
        },
        moderate = {
            animSet = "move_m@drunk@moderatedrunk",
            speedPenalty = 0.2
        },
        severe = {
            animSet = "move_m@drunk@verydrunk",
            speedPenalty = 0.4
        }
    },
    
    -- Health effects
    HealthEffects = {
        hypothermiaOnset = -10,   -- Temperature where health damage begins
        mildDamage = 1,           -- Damage per tick for mild hypothermia
        moderateDamage = 3,       -- Damage per tick for moderate hypothermia
        severeDamage = 5          -- Damage per tick for severe hypothermia
    },
    
    -- Recovery rates when warming up
    Recovery = {
        nearHeatSource = 2.0,     -- Recovery multiplier near heat source
        indoors = 1.5,            -- Recovery multiplier when indoors
        baseRate = 1.0            -- Base recovery rate
    }
}

-- Weather effects configuration
Config.WeatherEffects = {
    -- Fire particle effects by weather
    FireEffects = {
        clear = {
            scale = 1.0,
            smokeIntensity = 0.3,
            flameHeight = 1.0
        },
        clouds = {
            scale = 0.9,
            smokeIntensity = 0.4,
            flameHeight = 0.9
        },
        overcast = {
            scale = 0.8,
            smokeIntensity = 0.5,
            flameHeight = 0.8
        },
        rain = {
            scale = 0.7,
            smokeIntensity = 0.7,
            flameHeight = 0.6
        },
        thunder = {
            scale = 0.6,
            smokeIntensity = 0.8,
            flameHeight = 0.5
        },
        foggy = {
            scale = 0.8,
            smokeIntensity = 0.9,
            flameHeight = 0.7
        },
        snow = {
            scale = 0.7,
            smokeIntensity = 0.6,
            flameHeight = 0.6
        },
        blizzard = {
            scale = 0.5,
            smokeIntensity = 0.9,
            flameHeight = 0.4
        },
        xmas = {
            scale = 0.7,
            smokeIntensity = 0.6,
            flameHeight = 0.6
        },
        halloween = {
            scale = 1.1,
            smokeIntensity = 0.8,
            flameHeight = 1.2,
            flameColor = {r = 0.5, g = 0.2, b = 0.7} -- Purple-ish flames for Halloween
        }
    },
    
    -- Fuel consumption multipliers by weather
    FuelConsumption = {
        clear = 1.0,
        clouds = 1.1,
        overcast = 1.2,
        rain = 1.5,
        thunder = 1.7,
        foggy = 1.3,
        snow = 1.6,
        blizzard = 2.0,
        xmas = 1.6,
        halloween = 1.2
    }
}

-- Temperature data by weather and time (°C)
-- Each entry uses 24-hour start/end times; tempMin should be ≤ tempMax
Config.Temperature = {
    extrasunny = { -- values in °C, typical daytime highs 18-32
        {startTime = 0,  endTime = 1,  tempMin = 22, tempMax = 23},
        {startTime = 1,  endTime = 2,  tempMin = 21, tempMax = 24},
        {startTime = 2,  endTime = 3,  tempMin = 22, tempMax = 22},
        {startTime = 3,  endTime = 4,  tempMin = 20, tempMax = 21},
        {startTime = 4,  endTime = 5,  tempMin = 20, tempMax = 21},
        {startTime = 5,  endTime = 6,  tempMin = 20, tempMax = 21},
        {startTime = 6,  endTime = 7,  tempMin = 20, tempMax = 24},
        {startTime = 7,  endTime = 8,  tempMin = 20, tempMax = 23},
        {startTime = 8,  endTime = 9,  tempMin = 20, tempMax = 24},
        {startTime = 9,  endTime = 10, tempMin = 21, tempMax = 24},
        {startTime = 10, endTime = 11, tempMin = 21, tempMax = 24},
        {startTime = 11, endTime = 12, tempMin = 22, tempMax = 24},
        {startTime = 12, endTime = 13, tempMin = 22, tempMax = 26},
        {startTime = 13, endTime = 14, tempMin = 24, tempMax = 29},
        {startTime = 14, endTime = 15, tempMin = 25, tempMax = 31},
        {startTime = 15, endTime = 16, tempMin = 26, tempMax = 32},
        {startTime = 16, endTime = 17, tempMin = 25, tempMax = 32},
        {startTime = 17, endTime = 18, tempMin = 24, tempMax = 30},
        {startTime = 18, endTime = 19, tempMin = 23, tempMax = 28},
        {startTime = 19, endTime = 20, tempMin = 22, tempMax = 27},
        {startTime = 20, endTime = 21, tempMin = 21, tempMax = 26},
        {startTime = 21, endTime = 22, tempMin = 20, tempMax = 24},
        {startTime = 22, endTime = 23, tempMin = 19, tempMax = 23},
        {startTime = 23, endTime = 24, tempMin = 18, tempMax = 22}
    },
    clouds = { -- values in °C, typical range 14-24
        {startTime = 0, endTime = 1, tempMin = 19, tempMax = 22},
        {startTime = 1, endTime = 2, tempMin = 18, tempMax = 22},
        {startTime = 2, endTime = 3, tempMin = 17, tempMax = 21},
        {startTime = 3, endTime = 4, tempMin = 16, tempMax = 20},
        {startTime = 4, endTime = 5, tempMin = 16, tempMax = 20},
        {startTime = 5, endTime = 6, tempMin = 15, tempMax = 19},
        {startTime = 6, endTime = 7, tempMin = 14, tempMax = 18},
        {startTime = 7, endTime = 8, tempMin = 14, tempMax = 18},
        {startTime = 8, endTime = 9, tempMin = 14, tempMax = 19},
        {startTime = 9, endTime = 10, tempMin = 15, tempMax = 20},
        {startTime = 10, endTime = 11, tempMin = 16, tempMax = 21},
        {startTime = 11, endTime = 12, tempMin = 17, tempMax = 22},
        {startTime = 12, endTime = 13, tempMin = 18, tempMax = 23},
        {startTime = 13, endTime = 14, tempMin = 19, tempMax = 24},
        {startTime = 14, endTime = 15, tempMin = 19, tempMax = 24},
        {startTime = 15, endTime = 16, tempMin = 18, tempMax = 23},
        {startTime = 16, endTime = 17, tempMin = 17, tempMax = 22},
        {startTime = 17, endTime = 18, tempMin = 16, tempMax = 21},
        {startTime = 18, endTime = 19, tempMin = 15, tempMax = 20},
        {startTime = 19, endTime = 20, tempMin = 14, tempMax = 19},
        {startTime = 20, endTime = 21, tempMin = 14, tempMax = 18},
        {startTime = 21, endTime = 22, tempMin = 15, tempMax = 19},
        {startTime = 22, endTime = 23, tempMin = 16, tempMax = 20},
        {startTime = 23, endTime = 24, tempMin = 17, tempMax = 21} 
    },
    clear = { -- values in °C, typical range 12-23
        {startTime = 0, endTime = 1, tempMin = 15, tempMax = 18},
        {startTime = 1, endTime = 2, tempMin = 14, tempMax = 17},
        {startTime = 2, endTime = 3, tempMin = 13, tempMax = 16},
        {startTime = 3, endTime = 4, tempMin = 12, tempMax = 15},
        {startTime = 4, endTime = 5, tempMin = 12, tempMax = 14},
        {startTime = 5, endTime = 6, tempMin = 11, tempMax = 13},
        {startTime = 6, endTime = 7, tempMin = 11, tempMax = 13},
        {startTime = 7, endTime = 8, tempMin = 12, tempMax = 14},
        {startTime = 8, endTime = 9, tempMin = 13, tempMax = 15},
        {startTime = 9, endTime = 10, tempMin = 15, tempMax = 17},
        {startTime = 10, endTime = 11, tempMin = 16, tempMax = 18},
        {startTime = 11, endTime = 12, tempMin = 17, tempMax = 19},
        {startTime = 12, endTime = 13, tempMin = 18, tempMax = 20},
        {startTime = 13, endTime = 14, tempMin = 19, tempMax = 21},
        {startTime = 14, endTime = 15, tempMin = 20, tempMax = 22},
        {startTime = 15, endTime = 16, tempMin = 21, tempMax = 23},
        {startTime = 16, endTime = 17, tempMin = 21, tempMax = 23},
        {startTime = 17, endTime = 18, tempMin = 20, tempMax = 22},
        {startTime = 18, endTime = 19, tempMin = 19, tempMax = 21},
        {startTime = 19, endTime = 20, tempMin = 18, tempMax = 20},
        {startTime = 20, endTime = 21, tempMin = 17, tempMax = 19},
        {startTime = 21, endTime = 22, tempMin = 16, tempMax = 18},
        {startTime = 22, endTime = 23, tempMin = 15, tempMax = 17},
        {startTime = 23, endTime = 24, tempMin = 15, tempMax = 18} 
    },
    },
    overcast = { -- values in °C, typical range 9-21
        {startTime = 0, endTime = 1, tempMin = 13, tempMax = 16},
        {startTime = 1, endTime = 2, tempMin = 12, tempMax = 15},
        {startTime = 2, endTime = 3, tempMin = 11, tempMax = 14},
        {startTime = 3, endTime = 4, tempMin = 10, tempMax = 13},
        {startTime = 4, endTime = 5, tempMin = 10, tempMax = 12},
        {startTime = 5, endTime = 6, tempMin = 9, tempMax = 11},
        {startTime = 6, endTime = 7, tempMin = 9, tempMax = 11},
        {startTime = 7, endTime = 8, tempMin = 10, tempMax = 12},
        {startTime = 8, endTime = 9, tempMin = 11, tempMax = 13},
        {startTime = 9, endTime = 10, tempMin = 13, tempMax = 15},
        {startTime = 10, endTime = 11, tempMin = 14, tempMax = 16},
        {startTime = 11, endTime = 12, tempMin = 15, tempMax = 17},
        {startTime = 12, endTime = 13, tempMin = 16, tempMax = 18},
        {startTime = 13, endTime = 14, tempMin = 17, tempMax = 19},
        {startTime = 14, endTime = 15, tempMin = 18, tempMax = 20},
        {startTime = 15, endTime = 16, tempMin = 19, tempMax = 21},
        {startTime = 16, endTime = 17, tempMin = 19, tempMax = 21},
        {startTime = 17, endTime = 18, tempMin = 18, tempMax = 20},
        {startTime = 18, endTime = 19, tempMin = 17, tempMax = 19},
        {startTime = 19, endTime = 20, tempMin = 16, tempMax = 18},
        {startTime = 20, endTime = 21, tempMin = 15, tempMax = 17},
        {startTime = 21, endTime = 22, tempMin = 14, tempMax = 16},
        {startTime = 22, endTime = 23, tempMin = 13, tempMax = 15},
        {startTime = 23, endTime = 24, tempMin = 13, tempMax = 16}
    },
    rain = { -- values in °C, typical range 7-19
        {startTime = 0, endTime = 1, tempMin = 11, tempMax = 14},
        {startTime = 1, endTime = 2, tempMin = 10, tempMax = 13},
        {startTime = 2, endTime = 3, tempMin = 9, tempMax = 12},
        {startTime = 3, endTime = 4, tempMin = 8, tempMax = 11},
        {startTime = 4, endTime = 5, tempMin = 8, tempMax = 10},
        {startTime = 5, endTime = 6, tempMin = 7, tempMax = 9},
        {startTime = 6, endTime = 7, tempMin = 7, tempMax = 9},
        {startTime = 7, endTime = 8, tempMin = 8, tempMax = 10},
        {startTime = 8, endTime = 9, tempMin = 9, tempMax = 11},
        {startTime = 9, endTime = 10, tempMin = 11, tempMax = 13},
        {startTime = 10, endTime = 11, tempMin = 12, tempMax = 14},
        {startTime = 11, endTime = 12, tempMin = 13, tempMax = 15},
        {startTime = 12, endTime = 13, tempMin = 14, tempMax = 16},
        {startTime = 13, endTime = 14, tempMin = 15, tempMax = 17},
        {startTime = 14, endTime = 15, tempMin = 16, tempMax = 18},
        {startTime = 15, endTime = 16, tempMin = 17, tempMax = 19},
        {startTime = 16, endTime = 17, tempMin = 17, tempMax = 19},
        {startTime = 17, endTime = 18, tempMin = 16, tempMax = 18},
        {startTime = 18, endTime = 19, tempMin = 15, tempMax = 17},
        {startTime = 19, endTime = 20, tempMin = 14, tempMax = 16},
        {startTime = 20, endTime = 21, tempMin = 13, tempMax = 15},
        {startTime = 21, endTime = 22, tempMin = 12, tempMax = 14},
        {startTime = 22, endTime = 23, tempMin = 11, tempMax = 13},
        {startTime = 23, endTime = 24, tempMin = 11, tempMax = 14}
    },
    thunder = { -- values in °C, typical range 6-18
        {startTime = 0, endTime = 1, tempMin = 10, tempMax = 13},
        {startTime = 1, endTime = 2, tempMin = 9, tempMax = 12},
        {startTime = 2, endTime = 3, tempMin = 8, tempMax = 11},
        {startTime = 3, endTime = 4, tempMin = 7, tempMax = 10},
        {startTime = 4, endTime = 5, tempMin = 7, tempMax = 9},
        {startTime = 5, endTime = 6, tempMin = 6, tempMax = 8},
        {startTime = 6, endTime = 7, tempMin = 6, tempMax = 8},
        {startTime = 7, endTime = 8, tempMin = 7, tempMax = 9},
        {startTime = 8, endTime = 9, tempMin = 8, tempMax = 10},
        {startTime = 9, endTime = 10, tempMin = 10, tempMax = 12},
        {startTime = 10, endTime = 11, tempMin = 11, tempMax = 13},
        {startTime = 11, endTime = 12, tempMin = 12, tempMax = 14},
        {startTime = 12, endTime = 13, tempMin = 13, tempMax = 15},
        {startTime = 13, endTime = 14, tempMin = 14, tempMax = 16},
        {startTime = 14, endTime = 15, tempMin = 15, tempMax = 17},
        {startTime = 15, endTime = 16, tempMin = 16, tempMax = 18},
        {startTime = 16, endTime = 17, tempMin = 16, tempMax = 18},
        {startTime = 17, endTime = 18, tempMin = 15, tempMax = 17},
        {startTime = 18, endTime = 19, tempMin = 14, tempMax = 16},
        {startTime = 19, endTime = 20, tempMin = 13, tempMax = 15},
        {startTime = 20, endTime = 21, tempMin = 12, tempMax = 14},
        {startTime = 21, endTime = 22, tempMin = 11, tempMax = 13},
        {startTime = 22, endTime = 23, tempMin = 10, tempMax = 12},
        {startTime = 23, endTime = 24, tempMin = 10, tempMax = 13}
    },
    foggy = { -- values in °C, typical range 8-20
        {startTime = 0, endTime = 1, tempMin = 12, tempMax = 15},
        {startTime = 1, endTime = 2, tempMin = 11, tempMax = 14},
        {startTime = 2, endTime = 3, tempMin = 10, tempMax = 13},
        {startTime = 3, endTime = 4, tempMin = 9, tempMax = 12},
        {startTime = 4, endTime = 5, tempMin = 9, tempMax = 11},
        {startTime = 5, endTime = 6, tempMin = 8, tempMax = 10},
        {startTime = 6, endTime = 7, tempMin = 8, tempMax = 10},
        {startTime = 7, endTime = 8, tempMin = 9, tempMax = 11},
        {startTime = 8, endTime = 9, tempMin = 10, tempMax = 12},
        {startTime = 9, endTime = 10, tempMin = 12, tempMax = 14},
        {startTime = 10, endTime = 11, tempMin = 13, tempMax = 15},
        {startTime = 11, endTime = 12, tempMin = 14, tempMax = 16},
        {startTime = 12, endTime = 13, tempMin = 15, tempMax = 17},
        {startTime = 13, endTime = 14, tempMin = 16, tempMax = 18},
        {startTime = 14, endTime = 15, tempMin = 17, tempMax = 19},
        {startTime = 15, endTime = 16, tempMin = 18, tempMax = 20},
        {startTime = 16, endTime = 17, tempMin = 18, tempMax = 20},
        {startTime = 17, endTime = 18, tempMin = 17, tempMax = 19},
        {startTime = 18, endTime = 19, tempMin = 16, tempMax = 18},
        {startTime = 19, endTime = 20, tempMin = 15, tempMax = 17},
        {startTime = 20, endTime = 21, tempMin = 14, tempMax = 16},
        {startTime = 21, endTime = 22, tempMin = 13, tempMax = 15},
        {startTime = 22, endTime = 23, tempMin = 12, tempMax = 14},
        {startTime = 23, endTime = 24, tempMin = 12, tempMax = 15}
    },
    snow = { -- values in °C, typical range -10-2
        {startTime = 0, endTime = 1, tempMin = -6, tempMax = -3},
        {startTime = 1, endTime = 2, tempMin = -7, tempMax = -4},
        {startTime = 2, endTime = 3, tempMin = -8, tempMax = -5},
        {startTime = 3, endTime = 4, tempMin = -9, tempMax = -6},
        {startTime = 4, endTime = 5, tempMin = -9, tempMax = -7},
        {startTime = 5, endTime = 6, tempMin = -10, tempMax = -8},
        {startTime = 6, endTime = 7, tempMin = -10, tempMax = -8},
        {startTime = 7, endTime = 8, tempMin = -9, tempMax = -7},
        {startTime = 8, endTime = 9, tempMin = -8, tempMax = -6},
        {startTime = 9, endTime = 10, tempMin = -6, tempMax = -4},
        {startTime = 10, endTime = 11, tempMin = -5, tempMax = -3},
        {startTime = 11, endTime = 12, tempMin = -4, tempMax = -2},
        {startTime = 12, endTime = 13, tempMin = -3, tempMax = -1},
        {startTime = 13, endTime = 14, tempMin = -2, tempMax = 0},
        {startTime = 14, endTime = 15, tempMin = -1, tempMax = 1},
        {startTime = 15, endTime = 16, tempMin = 0, tempMax = 2},
        {startTime = 16, endTime = 17, tempMin = 0, tempMax = 2},
        {startTime = 17, endTime = 18, tempMin = -1, tempMax = 1},
        {startTime = 18, endTime = 19, tempMin = -2, tempMax = 0},
        {startTime = 19, endTime = 20, tempMin = -3, tempMax = -1},
        {startTime = 20, endTime = 21, tempMin = -4, tempMax = -2},
        {startTime = 21, endTime = 22, tempMin = -5, tempMax = -3},
        {startTime = 22, endTime = 23, tempMin = -6, tempMax = -4},
        {startTime = 23, endTime = 24, tempMin = -6, tempMax = -3}
    },
    blizzard = { -- values in °C, typical range -12-0
        {startTime = 0, endTime = 1, tempMin = -8, tempMax = -5},
        {startTime = 1, endTime = 2, tempMin = -9, tempMax = -6},
        {startTime = 2, endTime = 3, tempMin = -10, tempMax = -7},
        {startTime = 3, endTime = 4, tempMin = -11, tempMax = -8},
        {startTime = 4, endTime = 5, tempMin = -11, tempMax = -9},
        {startTime = 5, endTime = 6, tempMin = -12, tempMax = -10},
        {startTime = 6, endTime = 7, tempMin = -12, tempMax = -10},
        {startTime = 7, endTime = 8, tempMin = -11, tempMax = -9},
        {startTime = 8, endTime = 9, tempMin = -10, tempMax = -8},
        {startTime = 9, endTime = 10, tempMin = -8, tempMax = -6},
        {startTime = 10, endTime = 11, tempMin = -7, tempMax = -5},
        {startTime = 11, endTime = 12, tempMin = -6, tempMax = -4},
        {startTime = 12, endTime = 13, tempMin = -5, tempMax = -3},
        {startTime = 13, endTime = 14, tempMin = -4, tempMax = -2},
        {startTime = 14, endTime = 15, tempMin = -3, tempMax = -1},
        {startTime = 15, endTime = 16, tempMin = -2, tempMax = 0},
        {startTime = 16, endTime = 17, tempMin = -2, tempMax = 0},
        {startTime = 17, endTime = 18, tempMin = -3, tempMax = -1},
        {startTime = 18, endTime = 19, tempMin = -4, tempMax = -2},
        {startTime = 19, endTime = 20, tempMin = -5, tempMax = -3},
        {startTime = 20, endTime = 21, tempMin = -6, tempMax = -4},
        {startTime = 21, endTime = 22, tempMin = -7, tempMax = -5},
        {startTime = 22, endTime = 23, tempMin = -8, tempMax = -6},
        {startTime = 23, endTime = 24, tempMin = -8, tempMax = -5}
    },
    xmas = { -- values in °C, typical range -9-3
        {startTime = 0, endTime = 1, tempMin = -5, tempMax = -2},
        {startTime = 1, endTime = 2, tempMin = -6, tempMax = -3},
        {startTime = 2, endTime = 3, tempMin = -7, tempMax = -4},
        {startTime = 3, endTime = 4, tempMin = -8, tempMax = -5},
        {startTime = 4, endTime = 5, tempMin = -8, tempMax = -6},
        {startTime = 5, endTime = 6, tempMin = -9, tempMax = -7},
        {startTime = 6, endTime = 7, tempMin = -9, tempMax = -7},
        {startTime = 7, endTime = 8, tempMin = -8, tempMax = -6},
        {startTime = 8, endTime = 9, tempMin = -7, tempMax = -5},
        {startTime = 9, endTime = 10, tempMin = -5, tempMax = -3},
        {startTime = 10, endTime = 11, tempMin = -4, tempMax = -2},
        {startTime = 11, endTime = 12, tempMin = -3, tempMax = -1},
        {startTime = 12, endTime = 13, tempMin = -2, tempMax = 0},
        {startTime = 13, endTime = 14, tempMin = -1, tempMax = 1},
        {startTime = 14, endTime = 15, tempMin = 0, tempMax = 2},
        {startTime = 15, endTime = 16, tempMin = 1, tempMax = 3},
        {startTime = 16, endTime = 17, tempMin = 1, tempMax = 3},
        {startTime = 17, endTime = 18, tempMin = 0, tempMax = 2},
        {startTime = 18, endTime = 19, tempMin = -1, tempMax = 1},
        {startTime = 19, endTime = 20, tempMin = -2, tempMax = 0},
        {startTime = 20, endTime = 21, tempMin = -3, tempMax = -1},
        {startTime = 21, endTime = 22, tempMin = -4, tempMax = -2},
        {startTime = 22, endTime = 23, tempMin = -5, tempMax = -3},
        {startTime = 23, endTime = 24, tempMin = -5, tempMax = -2}
    },
    -- halloween = { -- values in °C, typical range 4-16
    --     {startTime = 0, endTime = 1, tempMin = 8, tempMax = 11},
    --     {startTime = 1, endTime = 2, tempMin = 7, tempMax = 10},
    --     {startTime = 2, endTime = 3, tempMin = 6, tempMax = 9},
    --     {startTime = 3, endTime = 4, tempMin = 5, tempMax = 8},
    --     {startTime = 4, endTime = 5, tempMin = 5, tempMax = 7},
    --     {startTime = 5, endTime = 6, tempMin = 4, tempMax = 6},
    --     {startTime = 6, endTime = 7, tempMin = 4, tempMax = 6},
    --     {startTime = 7, endTime = 8, tempMin = 5, tempMax = 7},
    --     {startTime = 8, endTime = 9, tempMin = 6, tempMax = 8},
    --     {startTime = 9, endTime = 10, tempMin = 8, tempMax = 10},
    --     {startTime = 10, endTime = 11, tempMin = 9, tempMax = 11},
    --     {startTime = 11, endTime = 12, tempMin = 10, tempMax = 12},
    --     {startTime = 12, endTime = 13, tempMin = 11, tempMax = 13},
    --     {startTime = 13, endTime = 14, tempMin = 12, tempMax = 14},
    --     {startTime = 14, endTime = 15, tempMin = 13, tempMax = 15},
    --     {startTime = 15, endTime = 16, tempMin = 14, tempMax = 16},
    --     {startTime = 16, endTime = 17, tempMin = 14, tempMax = 16},
    --     {startTime = 17, endTime = 18, tempMin = 13, tempMax = 15},
    --     {startTime = 18, endTime = 19, tempMin = 12, tempMax = 14},
    --     {startTime = 19, endTime = 20, tempMin = 11, tempMax = 13},
    --     {startTime = 20, endTime = 21, tempMin = 10, tempMax = 12},
    --     {startTime = 21, endTime = 22, tempMin = 9, tempMax = 11},
    --     {startTime = 22, endTime = 23, tempMin = 8, tempMax = 10},
    --     {startTime = 23, endTime = 24, tempMin = 8, tempMax = 11}
    -- }
}

exports("GetWeatherConfig", function()
    return Config

end)


