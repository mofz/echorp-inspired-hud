local visible = false
local forced = false
local inVehicle = cache.vehicle and true or false
local plyPed = cache.ped

local compassMode = GetResourceKvpString('compassMode') or 'camera'
local compassSize = GetResourceKvpFloat('compassSize')

if compassMode ~= 'camera' or compassMode ~= 'player' then
    compassMode = 'camera'
end

if not compassSize or compassSize < 1 then
    compassSize = 1
end

local GetGameplayCamRot = GetGameplayCamRot
local GetEntityRotation = GetEntityRotation
local Wait = Wait

local math_ceil = math.ceil

lib.onCache('ped', function(value)
	plyPed = value
end)

local function getLocation()
    local plyPos = GetEntityCoords(plyPed)
    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(plyPos.x, plyPos.y, plyPos.z)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    -- local intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)
    local zone = GetNameOfZone(plyPos.x, plyPos.y, plyPos.z)
    local area = GetLabelText(zone)

    if not zone then zone = "UNKNOWN" end

    return {
        a = currentStreetName,
        b = area
    }
end

-- For the compass direction
CreateThread(function()
    local cachedHeading = 0.0

	while true do
        local show = inVehicle or forced

        if visible ~= show then
            visible = show
            SendReactMessage('setCompassVisible', { active = visible, size = compassSize })
        end

        if visible then
            local camRot = compassMode == 'player' and GetEntityRotation(plyPed, 2) or GetGameplayCamRot(2)
            local heading = math_ceil((360.0 - ((camRot.z + 360.0) % 360.0)))

            if cachedHeading ~= heading then
                cachedHeading = heading
                SendReactMessage('setHeading', heading)
            end
        end

        Wait(visible and 0 or 500)
	end
end)

CreateThread(function()
    while true do
        Wait(500)

        if visible then
            SendReactMessage('setStreet', getLocation())
        end
    end
end)

AddEventHandler('erp_hud:toggleLandHud', function(sentToggle)
    if sentToggle == nil then
        forced = not forced
        return
    end

    forced = sentToggle
end)

lib.onCache('vehicle', function(value)
    inVehicle = value and true or false
end)

---@param type string
AddEventHandler('erp_inventory:refreshed', function(type)
    if not forced or type ~= 'player' then return end

    if exports.erp_inventory:hasEnoughOfItem('compass', 1) then return end
    TriggerEvent('erp_hud:toggleLandHud', false)
end)

---@param loggedIn boolean whether the player is logged in or not
AddEventHandler('echo_interface:loggedIn', function(loggedIn)
	if loggedIn then return end
    TriggerEvent('erp_hud:toggleLandHud', false)
end)

RegisterCommand('compass', function(_, args)
    local mode = args and args[1] or ''
    mode = mode:lower()

    if mode ~= 'camera' and mode ~= 'player' then
        return TriggerEvent('sendNotification', { title = 'Compass', text = 'You did not provide a valid mode, try either "camera" or "player"', icon = 'compass', type = 'error' })
    end

    if compassMode == mode then
        return TriggerEvent('sendNotification', { title = 'Compass', text = 'Your compass is already set to this mode', icon = 'compass', type = 'inform' })
    end

    compassMode = mode
    SetResourceKvp('compassMode', mode)

    TriggerEvent('sendNotification', { title = 'Compass', text = ('Compass mode has been set to "%s"'):format(mode), icon = 'compass', type = 'success' })
end)

TriggerEvent('chat:addSuggestion', '/compass', 'Change the way the compass grabs your direction', {
    { name= 'camera or player', help = 'Use camera for the compass to grab based on your camera rotation, or use player to get it based on your ped rotation' }
})

RegisterNetEvent('echo_interface:setCompassSize', function(size)
    compassSize = size

    SetResourceKvpFloat('compassSize', size)
    SendReactMessage('setCompassSize', size)
end)

local isMapLoaded = false
local function loadMap()
    local defaultAspectRatio = 1920 / 1080 
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 2.6) - 0.008
    end
    RequestStreamedTextureDict('squaremap', false)
    while not HasStreamedTextureDictLoaded('squaremap') do
        Wait(50)
    end
    SetMinimapClipType(0)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, -0.14, 0.148, 0.165)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, -0.08, 0.115, 0.18)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, -0.055, 0.235, 0.275)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
    SetRadarZoom(1000)
end
CreateThread(function()
    while true do
        Wait(500) 
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        if inVehicle and not isMapLoaded then
            DisplayRadar(true)
            loadMap()
            isMapLoaded = true
        elseif not inVehicle and isMapLoaded then
            DisplayRadar(false)
            isMapLoaded = false
        end
    end
end)