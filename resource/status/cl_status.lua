local QBCore = exports['qb-core']:GetCoreObject()
local math_ceil = math.ceil

local plyPed = cache.ped
local plyId <const> = PlayerId()
local unarmed <const> = `WEAPON_UNARMED`
local inventory <const> = exports.ox_inventory

local playerFilter = ('player:%s'):format(cache.serverId)

spectatorMode = false
local isTalking = false
local visible = false
local weapon = {}
local CurrentWeapon = nil
local PlayerData = {}

lib.onCache('ped', function(value)
	plyPed = value
end)

local weaponImages = {
	[`WEAPON_UNARMED`] = '',
	[`WEAPON_KNIFE`] = 'nui://ox_inventory/web/images/weapon_knife.png',
	[`WEAPON_NIGHTSTICK`] = 'nui://ox_inventory/web/images/weapon_nightstick.png',
	[`WEAPON_HAMMER`] = 'nui://ox_inventory/web/images/weapon_hammer.png',
	[`WEAPON_BAT`] = 'nui://ox_inventory/web/images/weapon_bat.png',
	[`WEAPON_GOLFCLUB`] = 'nui://ox_inventory/web/images/weapon_golfclub.png',
	[`WEAPON_CROWBAR`] = 'nui://ox_inventory/web/images/weapon_crowbar.png',
	[`WEAPON_PISTOL`] = 'nui://ox_inventory/web/images/weapon_pistol.png',
	[`WEAPON_COMBATPISTOL`] = 'nui://ox_inventory/web/images/weapon_combatpistol.png',
	[`WEAPON_APPISTOL`] = 'nui://ox_inventory/web/images/weapon_appistol.png',
	[`WEAPON_PISTOL50`] = 'nui://ox_inventory/web/images/weapon_pistol50.png',
	[`WEAPON_MICROSMG`] = 'nui://ox_inventory/web/images/weapon_microsmg.png',
	[`WEAPON_SMG`] = 'nui://ox_inventory/web/images/weapon_smg.png',
	[`WEAPON_ASSAULTSMG`] = 'nui://ox_inventory/web/images/weapon_assaultsmg.png',
	[`WEAPON_ASSAULTRIFLE`] = 'nui://ox_inventory/web/images/weapon_assaultrifle.png',
	[`WEAPON_CARBINERIFLE`] = 'nui://ox_inventory/web/images/weapon_carbinerifle.png',
	[`WEAPON_ADVANCEDRIFLE`] = 'nui://ox_inventory/web/images/weapon_advancedrifle.png',
	[`WEAPON_MG`] = 'nui://ox_inventory/web/images/weapon_mg.png',
	[`WEAPON_COMBATMG`] = 'nui://ox_inventory/web/images/weapon_combatmg.png',
	[`WEAPON_PUMPSHOTGUN`] = 'nui://ox_inventory/web/images/weapon_pumpshotgun.png',
	[`WEAPON_SAWNOFFSHOTGUN`] = 'nui://ox_inventory/web/images/weapon_sawnoffshotgun.png',
	[`WEAPON_ASSAULTSHOTGUN`] = 'nui://ox_inventory/web/images/weapon_assaultshotgun.png',
	[`WEAPON_BULLPUPSHOTGUN`] = 'nui://ox_inventory/web/images/weapon_bullpupshotgun.png',
	[`WEAPON_STUNGUN`] = 'nui://ox_inventory/web/images/weapon_stungun.png',
	[`WEAPON_SNIPERRIFLE`] = 'nui://ox_inventory/web/images/weapon_sniperrifle.png',
	[`WEAPON_HEAVYSNIPER`] = 'nui://ox_inventory/web/images/weapon_heavysniper.png',
	[`WEAPON_REMOTESNIPER`] = 'nui://ox_inventory/web/images/weapon_remotesniper.png',
	[`WEAPON_GRENADELAUNCHER`] = 'nui://ox_inventory/web/images/weapon_grenadelauncher.png',
	[`WEAPON_RPG`] = 'nui://ox_inventory/web/images/weapon_rpg.png',
	[`WEAPON_MINIGUN`] = 'nui://ox_inventory/web/images/weapon_minigun.png',
	[`WEAPON_GRENADE`] = 'nui://ox_inventory/web/images/weapon_grenade.png',
	[`WEAPON_STICKYBOMB`] = 'nui://ox_inventory/web/images/weapon_stickybomb.png',
	[`WEAPON_SMOKEGRENADE`] = 'nui://ox_inventory/web/images/weapon_smokegrenade.png',
	[`WEAPON_BZGAS`] = 'nui://ox_inventory/web/images/weapon_bzgas.png',
	[`WEAPON_MOLOTOV`] = 'nui://ox_inventory/web/images/weapon_molotov.png',
	[`WEAPON_FIREEXTINGUISHER`] = 'nui://ox_inventory/web/images/weapon_fireextinguisher.png',
	[`WEAPON_PETROLCAN`] = 'nui://ox_inventory/web/images/weapon_petrolcan.png',
	[`WEAPON_DIGISCANNER`] = 'nui://ox_inventory/web/images/weapon_digiscanner.png',
	[`WEAPON_BRIEFCASE`] = 'nui://ox_inventory/web/images/weapon_briefcase.png',
	[`WEAPON_BRIEFCASE_02`] = 'nui://ox_inventory/web/images/weapon_briefcase_02.png',
	[`WEAPON_BALL`] = 'nui://ox_inventory/web/images/weapon_ball.png',
	[`WEAPON_FLARE`] = 'nui://ox_inventory/web/images/weapon_flare.png',

	[`weapon_ytaz`] = 'nui://ox_inventory/web/images/weapon_stungun.png',
	[`weapon_gtaz`] = 'nui://ox_inventory/web/images/weapon_stungun.png',
	[`weapon_btaz`] = 'nui://ox_inventory/web/images/weapon_stungun.png',
	[`weapon_ptaz`] = 'nui://ox_inventory/web/images/weapon_stungun.png',
}

local function getWeaponImagePath(itemName, weaponHash)

	local oxImage = ('nui://ox_inventory/web/images/%s.png'):format(itemName:lower())

	if weaponImages[weaponHash] then
		return weaponImages[weaponHash]
	end
	
	return oxImage
end

local function toggleHud(toggle)
    local newState = not visible
    if toggle ~= nil then
        newState = toggle
    end
    visible = newState
    SendReactMessage('setHudVisible', {
        visible = visible
    })
end

AddEventHandler('echo_interface:loggedIn', function(loggedIn)
    toggleHud(loggedIn)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    if PlayerData.metadata then
        PlayerData.metadata.hunger = newHunger
        PlayerData.metadata.thirst = newThirst
    end
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    if PlayerData.metadata then
        PlayerData.metadata.stress = newStress
    end
end)

CreateThread(function()
	while true do
		Wait(500)

		local currentPlayerData = QBCore.Functions.GetPlayerData()
		if currentPlayerData and currentPlayerData.citizenid then
			PlayerData = currentPlayerData
		end

		if visible and PlayerData and PlayerData.citizenid then
			SendReactMessage('setPauseMenu', pauseMenu or IsScreenFadedOut() or IsScreenFadingOut() or blackbars)

			spectatorMode = NetworkIsActivitySpectator()

			local hunger = PlayerData.metadata and PlayerData.metadata.hunger and math_ceil(PlayerData.metadata.hunger) or 100
			local thirst = PlayerData.metadata and PlayerData.metadata.thirst and math_ceil(PlayerData.metadata.thirst) or 100
			local stress = PlayerData.metadata and PlayerData.metadata.stress and math_ceil(PlayerData.metadata.stress) or 0

			local plyHealth = GetEntityHealth(plyPed) - 100
			local plyArmor = GetPedArmour(plyPed)
			local plyOxygen = GetPlayerUnderwaterTimeRemaining(plyId) * 10

			if plyHealth < 0 then plyHealth = 0 end
			if stress < 0.1 then stress = 0 end

			local health = {
				bloodLevel = PlayerData.metadata and PlayerData.metadata.injuries and PlayerData.metadata.injuries.blood or 0,
				fractureLevel = PlayerData.metadata and PlayerData.metadata.injuries and PlayerData.metadata.injuries.fractures or 0,
				burnsLevel = PlayerData.metadata and PlayerData.metadata.injuries and PlayerData.metadata.injuries.burns or 0,
			}

			local bloodLevel = math_ceil(health.bloodLevel * 100 / 10)
			local fractureLevel = math_ceil(health.fractureLevel / 3 * 100)
			local burnsLevel = math_ceil(health.burnsLevel * 100 / 10)

			local caffeineP = PlayerData.metadata and PlayerData.metadata.caffeinated and getCaffeinePercentage(PlayerData.metadata.caffeinated.start, PlayerData.metadata.caffeinated.finish) or 0

			SendReactMessage('setStatus', {
				health = { visible = true, value = plyHealth, warning = plyHealth < 40, danger = plyHealth < 20 },
				armor = { visible = true, value = plyArmor, danger = plyArmor > 0 and plyArmor < 25 },
				hunger = { visible = true, value = hunger, warning = hunger < 30, danger = hunger < 10 },
				thirst = { visible = true, value = thirst, warning = thirst < 30, danger = thirst < 10 },
				stress = { visible = stress > 0, value = stress, warning = stress > 50, danger = stress > 80 },
				oxygen = { visible = plyOxygen < 100, value = plyOxygen, warning = plyOxygen < 30, danger = plyOxygen < 10 },
				fracture = { visible = fractureLevel > 0, value = fractureLevel, warning = fractureLevel > 30, danger = fractureLevel > 60 },
				blood = { visible = bloodLevel > 0, value = bloodLevel, warning = bloodLevel > 0, danger = bloodLevel > 20 },
				coffee = { visible = caffeineP > 0, value = caffeineP, warning = caffeineP < 40, danger = caffeineP < 20 },
				burns = { visible = burnsLevel > 0, value = burnsLevel, warning = burnsLevel > 0, danger = burnsLevel > 20 },
			})
		end
	end
end)

CreateThread(function()
	while true do
		Wait(100)
		local talking = NetworkIsPlayerTalking(plyId)
		if talking ~= isTalking then
			isTalking = talking
			SendReactMessage('setTalking', isTalking)
		end
	end
end)

AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
	CurrentWeapon = currentWeapon
end)

local function GetWeaponData(itemName, metadata, weaponHash)
	local oxItems = exports.ox_inventory:Items()
	local item = oxItems[itemName]
	
	if not item then 
		return nil
	end

	local weaponName = item.label or itemName
	if metadata then
		if metadata.label then
			weaponName = metadata.label
		elseif metadata.title then
			weaponName = metadata.title
		end
	end

	local weaponImage = ''
	if metadata and metadata.image then
		weaponImage = metadata.image
	elseif item.client and item.client.image then
		weaponImage = item.client.image
	else

		weaponImage = getWeaponImagePath(itemName, weaponHash)
	end

	local weaponDescription = ''
	if metadata and metadata.description then
		weaponDescription = metadata.description
	elseif item.client and item.client.description then
		weaponDescription = item.client.description
	elseif item.description then
		weaponDescription = item.description
	end

	return {
		name = weaponName,
		image = weaponImage,
		description = weaponDescription,
		label = item.label or itemName
	}
end

ItemIdFromHash = function(weaponHash)
	local hash = weaponHash or GetSelectedPedWeapon(plyPed)

	if CurrentWeapon and CurrentWeapon.hash == hash then
		return CurrentWeapon.name
	end

	if hash == `weapon_ytaz` or hash == `weapon_gtaz` or hash == `weapon_btaz` or hash == `weapon_ptaz` then
		return 'stungun'
	end

	local oxItems = exports.ox_inventory:Items()
	for itemName, itemData in pairs(oxItems) do
		if itemData.weapon and itemData.hash == hash then
			return itemName
		end
	end

	return false
end

local function updateWeapon()
	local armed = GetSelectedPedWeapon(plyPed)
	
	if not armed or armed == unarmed then
		if weapon.name then 
			weapon = {}
			SendReactMessage('setWeapon', nil)
		end
		Wait(750)
		return
	end

	local itemId = ItemIdFromHash(armed)
	if not itemId then 
		return 
	end

	local weaponMetadata = nil
	if CurrentWeapon and CurrentWeapon.name == itemId then
		weaponMetadata = CurrentWeapon.metadata
	end

	local weaponData = GetWeaponData(itemId, weaponMetadata, armed)
	if not weaponData then
		return
	end

	local clipAmmo = select(2, GetAmmoInClip(plyPed, armed)) or 0
	local maxAmmo = GetAmmoInPedWeapon(plyPed, armed) or 0
	local reserveAmmo = maxAmmo - clipAmmo

	local newWeaponData = {
		name = weaponData.name,
		ammo = clipAmmo,
		maxAmmo = reserveAmmo,
		img = weaponData.image,
		description = weaponData.description,
		label = weaponData.label
	}

	if newWeaponData.name ~= weapon.name or 
	   newWeaponData.ammo ~= weapon.ammo or 
	   newWeaponData.maxAmmo ~= weapon.maxAmmo or
	   newWeaponData.img ~= weapon.img then
		
		weapon = newWeaponData
		SendReactMessage('setWeapon', weapon)
	end
end

CreateThread(function()
	while true do
		Wait(100)
		updateWeapon()
	end
end)

AddStateBagChangeHandler('proximity', playerFilter, function(_, _, value, _, replicated)
	if not replicated then
		SendReactMessage('setProximity', value.index)
	end
end)

RegisterNetEvent('pma-voice:radioActive', function(talking)
	SendReactMessage('setRadioActive', talking)
end)