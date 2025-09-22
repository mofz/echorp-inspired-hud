local QBCore = exports['qb-core']:GetCoreObject()

local loggedIn = false
local toggledHud = true
local preventToggleOverride = false 

CreateThread(function()
	while not QBCore do
		Wait(100)
	end
	
	while not QBCore.Functions.GetPlayerData().citizenid do
		Wait(100)
	end

	loggedIn = true
	TriggerEvent('echo_interface:loggedIn', loggedIn)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	loggedIn = true
	TriggerEvent('echo_interface:loggedIn', loggedIn)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	loggedIn = false
	TriggerEvent('echo_interface:loggedIn', loggedIn)
end)


RegisterNetEvent('multicharacter:client:logout', function()
	loggedIn = false
	TriggerEvent('echo_interface:loggedIn', loggedIn)
end)

---@param state boolean
---@param isCommand boolean Whether or not it is a command which is toggling the hud
local function toggleHud(state, isCommand)
	local newState = not toggledHud
	if state ~= nil then
		newState = state
	end

	print('Attempting to toggle HUD', toggledHud, state, newState, isCommand)

	if newState == toggledHud then
		print('Nevermind, we are already the wanted state anyway')
		return
	end

	if not isCommand and newState and preventToggleOverride then
		print('This does not appear to be a command we are trying to set it to true despite toggle override being enabled')
		return
	end 

	preventToggleOverride = not newState and isCommand
	toggledHud = newState

	print('Firing react message for toggled', toggledHud)
	SendReactMessage('setToggled', toggledHud)
end

RegisterCommand("toggleHud", function()
	toggleHud(not toggledHud, true)
end, false)

TriggerEvent('chat:addSuggestion', '/togglehud', 'Toggle the health, driving and weapon HUD elements')

AddEventHandler('toggleHud', toggleHud)

exports('toggleHud', toggleHud)

local function carHud(state)
	SendReactMessage('carHud', state)
end

RegisterCommand("carhud", function(source, args)
	carHud(string.lower(args[1]))
end, false)

local function loadMap()
    local defaultAspectRatio = 1920 / 1080 
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 2.6) - 0.008
    end
    RequestStreamedTextureDict('squaremap', false)
    if not HasStreamedTextureDictLoaded('squaremap') then
        Wait(150)
    end
    SetMinimapClipType(0)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, -0.14, 0.148, 0.165)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, -0.08, 0.115, 0.18)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, -0.055, 0.235, 0.275)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(0)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
    SetRadarZoom(1000)
end
CreateThread(function()
    local minimap = RequestScaleformMovie('squaremap')
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    loadMap()
end)
loadMap()