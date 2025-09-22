local vehicle = cache.vehicle

local arenaGame = false



local math_ceil = math.ceil

local GetEntitySpeed = GetEntitySpeed



local speedMult = 2.23694

local fuelAlarm = false

local carhudPos = GetResourceKvpString('carhudpos') or 'center'



local radarActive = false



local seatbelt = LocalPlayer.state.seatbelt

local inventory = LocalPlayer.state.inventoryOpen



if seatbelt == nil then

    LocalPlayer.state.seatbelt = false

    seatbelt = false

end



local function getVehicleSpeed()

    local speed = GetEntitySpeed(vehicle)

    if speed < 0 then

        speed = speed * -1

    end

    return speed * speedMult

end



local function getRpmPercentage(rpm)

    return math_ceil(rpm * 1000)

end





local function getEngineHealthPercentage(health)

    local percentage = ((health + 4000) / 5000) * 100

    percentage = math.max(0, math.min(percentage, 100))

    return percentage

end



local function alertLowFuel()

    if fuelAlarm then return end

    fuelAlarm = true



    lib.notify('You are on low fuel', 3000, 'error')



    CreateThread(function()

        for _=0, 4 do

            PlaySound(-1, "5_SEC_WARNING", "HUD_MINI_GAME_SOUNDSET", false, 0, true)

            Wait(250)

        end



        Wait(60000)



        fuelAlarm = false

    end)

end



lib.onCache('vehicle', function(value)

    vehicle = value



    -- SendReactMessage('setCarHudPosition', carhudPos)

    SendReactMessage('setCarHudVisibility', vehicle and true or false)



    if not vehicle then

        LocalPlayer.state.seatbelt = false

        return

    end



    -- Thread for updating vehicle state (gears, fuel, engine health, nitrous, engine running, manual)

    CreateThread(function()

        while vehicle and vehicle == value do

            local state = Entity(vehicle).state



            local gear = GetVehicleCurrentGear(vehicle)

            local engineHealth = getEngineHealthPercentage(GetVehicleEngineHealth(vehicle))



            local fuel = exports['cdn-fuel']:GetFuel(vehicle)



            -- ** IMPORTANT: Adjust 'fuelPercentage' calculation based on LegacyFuel's output **

            -- If LegacyFuel returns a value between 0.0 and 1.0 (e.g., 0.99 for 99%), use:

            -- local fuelPercentage = fuel * 100

            -- If LegacyFuel returns a value between 0 and 100 (e.g., 99 for 99%), use:

            local fuelPercentage = fuel



            -- Ensure fuelPercentage is correctly clamped between 0 and 100

            fuelPercentage = math.max(0, math.min(fuelPercentage, 100))



            -- local isElectric = GetIsVehicleElectric(GetEntityModel(vehicle))

            -- if fuelPercentage < 12 and not isElectric then

            --     alertLowFuel()

            -- end



            -- Sending vehicle state to React, including the corrected fuel format

            SendReactMessage('updateVehicleState', {

                gears = gear == 0 and 'R' or gear,

                fuel = { -- This sends fuel as an object with 'podium' and 'regular' keys

                    podium = 0, -- Set to 0 if you don't have a separate "podium" fuel type

                    regular = fuelPercentage -- This is your main fuel value

                },

                engineHealth = engineHealth,

                nitrous = state.nitrousInstalled and state.nitrousCount or 0,

                engineRunning = GetIsVehicleEngineRunning(vehicle) or false,

                isManual = state.transmissionMode == 'manual'

            })



            Wait(1000) -- Update this data every 1 second

        end

    end)



    -- Thread for updating dynamic vehicle state (speed, RPM)

    CreateThread(function()

        while vehicle and vehicle == value do

            local speed = getVehicleSpeed()

            local rpm = getRpmPercentage(GetVehicleCurrentRpm(vehicle))



            SendReactMessage('updateVehicleState', {

                speed = math.ceil(speed),

                rpm = rpm,

            })



            Wait(100) -- Update speed/RPM more frequently (every 0.1 seconds)

        end

    end)

end)



-- CreateThread(function()

--     while true do

--         Wait(500) -- Adjust as needed; no need to run every frame



--         local shouldDisplayRadar = (vehicle or arenaGame or spectatorMode) and not inventory and toggledHud



--         if radarActive ~= shouldDisplayRadar then

--             radarActive = shouldDisplayRadar

--             DisplayRadar(radarActive)

--             SendReactMessage('setRadar', radarActive)

--         end

--     end

-- end)



-- Zooooom, super fast thread! (Radar and Seatbelt control)

Citizen.CreateThread(function()

    RequestStreamedTextureDict("squaremap", true)

    while not HasStreamedTextureDictLoaded("squaremap") do

        Wait(10)

    end



    SetMinimapClipType(1)

    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0, -0.040, 0.1638, 0.183)

    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0, 0.015, 0.128, 0.20)

    SetMinimapComponentPosition('minimap_blur', 'L', 'B', 0.0, 0.015, 0.128, 0.20)

end)



-- Seatbelt functions

local QBCore = exports['core']:GetCoreObject()



local function toggleBelt()

    if not vehicle then return end

    -- Prevent toggling seatbelt in certain vehicle classes (e.g., bikes, Class 13 is usually bikes)

    if GetVehicleClass(vehicle) == 13 then return end



    -- Get current speed to prevent toggling at very high speeds

    local speed = (GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()) and GetEntitySpeed(vehicle) * 2.236936 or 0

    if speed > 75.0 then

        exports.echo_interface:sendAlert('inform', 'Too high speed to toggle seatbelt')

        return

    end



    seatbelt = not seatbelt -- Toggle seatbelt state

    

    if seatbelt then

        TriggerEvent("seatbelt:client:ToggleSeatbelt", true) -- Trigger client event for seatbelt (if other scripts listen)

        exports.echo_interface:sendAlert('success', 'Seat Belt Enabled')

        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'buckle', 0.25) -- Play buckle sound

    else

        TriggerEvent("seatbelt:client:ToggleSeatbelt", false) -- Trigger client event for seatbelt

        exports.echo_interface:sendAlert('error', 'Seat Belt Disabled')

        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'unbuckle', 0.25) -- Play unbuckle sound

    end



    LocalPlayer.state.seatbelt = seatbelt -- Update player state bag

end



-- State bag change handler for seatbelt

AddStateBagChangeHandler('seatbelt', ('player:%s'):format(cache.serverId), function(bagName, key, value, _, replicated)

    if replicated then return end -- Only process local changes if not replicated



    seatbelt = value or false

    SendReactMessage('setSeatbelt', seatbelt) -- Send seatbelt state to React

end)



-- State bag change handler for inventory open status

AddStateBagChangeHandler('inventoryOpen', ('player:%s'):format(cache.serverId), function(bagName, key, value, _, replicated)

    if replicated then return end -- Only process local changes if not replicated

    inventory = value or false

end)



-- State bag change handler for arena game status

AddStateBagChangeHandler('arena', ('player:%s'):format(cache.serverId), function(bagName, key, value)

    arenaGame = value and true or false

end)



-- Key mapping and commands for seatbelt toggle

RegisterKeyMapping("seatbelt", "Toggle Seatbelt", "keyboard", "B")

RegisterCommand("-seatbelt", function() end, false) -- Empty command for key release if needed



RegisterCommand('seatbelt', function()

    if IsNuiFocused() then return end -- Prevent toggle if NUI is focused (e.g., menu open)

    toggleBelt()

end, false)



