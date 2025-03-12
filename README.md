# Weather and Temperature System

## Overview

This resource provides a realistic weather and temperature simulation for FiveM servers. It calculates environmental temperature based on multiple dynamic factors such as season, time of day, altitude, weather conditions, biome type, nearby water bodies, and even player-specific details like clothing insulation and indoor/outdoor status. The system is designed to work with external weather resources (e.g., `renewed-weathersync`) and popular frameworks (ESX and QBCore) while also functioning in a standalone mode.

## Features

- **Realistic Temperature Calculation:**
  - **Base Temperature:** Uses seasonal base values combined with time-of-day adjustments.
  - **Modifiers:** Applies weather, altitude, biome, and water proximity modifiers.
  - **Smoothing Algorithm:** Utilizes an exponential weighted moving average to smooth out rapid changes.
  
- **Comfort Metrics:**
  - **Wind Chill & Heat Index:** Calculates adjustments for cold (wind chill) and hot (heat index) conditions.
  - **Dew Point:** Computes dew point based on temperature and humidity.
  - **Feels Like Temperature:** Provides a “feels like” value considering environmental factors.

- **Dynamic Updates:**
  - Continuously updates temperature data via Citizen threads.
  - Monitors player state (e.g., indoors/outdoors, nearby water bodies) and biome detection.
  - Synchronizes data between client and server for consistency.

- **Framework Integration:**
  - Supports ESX and QBCore frameworks with automatic fallback to standalone mode.
  - Integrates with external weather resources (e.g., `renewed-weathersync`) for real-time weather data.

- **User & Admin Commands:**
  - **Client Command (`/checktemp`):** Allows players to check current temperature and “feels like” values.
  - **Server Commands:**
    - `/servertemp` – Displays current server weather, temperature, wind speed, and humidity (admin-only).
    - `/settemp [value]` – Allows admins to set the server temperature manually.

## Files Description

### client.lua

This script handles the core temperature calculations and environmental simulations on the client side. Key functions include:

- **Temperature Calculations:**
  - `calculateRealisticTemperature()`: Combines base seasonal temperature with modifiers (weather, time, altitude, etc.).
  - `addTemperatureToHistory(temp)`: Smooths temperature changes using an exponential weighted moving average.
  - `getPerceivedTemperature()`: Computes the temperature as perceived by the player, factoring in wind chill or heat index.
  
- **Comfort & Environmental Metrics:**
  - `calculateDewPoint(temp, humidity)`: Computes the dew point.
  - `calculateFeelsLikeTemperature(temp, windSpeed, humidity)`: Calculates the “feels like” temperature.
  - `getWindChillFactor()` and `getHeatIndex()`: Determine temperature adjustments for cold and hot conditions.
  
- **Environmental Detection:**
  - `GetRoofState()`: Checks if the player is indoors.
  - `detectBiomeType(coords)`: Determines the biome type based on player coordinates.
  - Nearby water body detection for moderating temperature.
  
- **Event & Command Handling:**
  - A Citizen thread periodically updates environmental conditions and triggers the event `weather-temperature:update` to broadcast current weather and temperature data.
  - Registers the `/checktemp` command, which notifies the player with current temperature and “feels like” information.

- **Export:**
  - The function `getTemperatureData()` is exported for use by other scripts. It returns a table with detailed temperature and weather data.

### server.lua

This script manages server-side synchronization and administrative controls for weather and temperature data. Key functions include:

- **Framework & Status Integration:**
  - Supports ESX and QBCore frameworks to update player status based on environmental conditions.
  - Provides the `UpdatePlayerStatus()` function that adjusts player status values.

- **Event Handlers:**
  - Listens for `weather-temperature:requestData` from clients and responds with the current server temperature, wind speed, humidity, and weather.
  - Processes `weather-temperature:updateStatus` events to adjust player-specific statuses.

- **Server Commands:**
  - **`/servertemp`:** Displays the current server temperature, weather, wind speed, and humidity (admin-only).
  - **`/settemp [value]`:** Allows admins to set the server temperature manually. The updated temperature is then synchronized with all clients.

- **Weather Data Synchronization:**
  - Runs a continuous thread that periodically updates server weather data based on external resources or defaults, adjusts humidity values, and broadcasts updated data to all connected clients.

## Configuration

- **Framework Selection:**  
  Set via `Config.Framework`. Supported values include `esx`, `qbox`, or `standalone`.
  
- **Weather Resource Integration:**  
  Use `Config.weatherResource` (e.g., set to `renewed-weathersync`) if integrating with an external weather system.
  
- **Debug Mode:**  
  Enable debugging by setting `Config.Debug` to `true` if detailed logs are needed.
  
- **Heat Zones & Cold Settings:**  
  Configure properties such as `Config.HeatZone.radius` and thresholds in the script as required.

## Commands

- **Client Side:**
  - `/checktemp` – Displays current temperature and “feels like” temperature information.

- **Server Side (Admin Only):**
  - `/servertemp` – Shows server weather details.
  - `/settemp [value]` – Manually sets the server temperature.

## Exports

- **`getTemperatureData`**  
  This function returns a table containing:
  - `temperature`: The current actual temperature.
  - `perceived`: The perceived temperature after wind chill/heat index adjustments.
  - `feelsLike`: The “feels like” temperature.
  - `windChill`: The calculated wind chill value.
  - `heatIndex`: The calculated heat index.
  - `weather`: The current weather condition.
  - `season`: The current season.
  - `timeOfDay`: Indicates whether it is day or night.
  - `humidity`: The current humidity percentage.
  - `windSpeed`: The current wind speed.
  - `dewPoint`: The calculated dew point.
  - `isIndoors`: Boolean value indicating if the player is indoors.
  - `biome`: The detected biome type.
  - `clothingInsulation`: Calculated insulation value based on player clothing.

### Usage Example for Export

Below is an example of how another script or resource can call the exported `getTemperatureData()` function:

```lua
-- Example: Using the exported function getTemperatureData from another resource

-- Ensure that the resource 'weather-temperature' is started before using the export
local tempData = exports['weather-temperature']:getTemperatureData()

-- Print out temperature details to the console
print(string.format("Current Temperature: %.1f°C", tempData.temperature))
print(string.format("Feels Like Temperature: %.1f°C", tempData.feelsLike))

-- You can also use the data to drive other gameplay mechanics
if tempData.temperature < 5 then
    -- Apply a cold effect to the player, e.g., reducing stamina or speed
    TriggerEvent('player:applyColdEffect', tempData.temperature)
end
```

## Usage

1. **Installation:**
   - Place the resource folder in your FiveM resources directory.
   - Configure any necessary settings in your `Config.lua` (or within the script files if no separate configuration exists).

2. **Integration:**
   - Ensure your server is set up with the required frameworks (ESX or QBCore) if needed.
   - If using an external weather resource (e.g., `renewed-weathersync`), verify it is installed and configured correctly.

3. **Starting the Resource:**
   - Add the resource to your server configuration file and start it.
   - Use the provided commands in-game to check and manage temperature data.

4. **Other Scripts:**
   - Other resources can call the exported `getTemperatureData()` function to retrieve the current temperature and environmental data.

## Acknowledgements

This system was developed to enhance environmental realism in FiveM servers by providing detailed and dynamic weather and temperature simulation.
