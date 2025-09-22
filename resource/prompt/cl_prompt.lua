---@class PromptParams
---@field id string
---@field active boolean
---@field text string
---@field control string
---@field hold? boolean

---@type PromptParams | {}
local prompt = {}

---@param id string
---@param text string
---@param control string
---@param hold? boolean
local function showPrompt(id, text, control, hold)
	prompt = {
		id = id,
		text = text,
		control = control,
		hold = hold or false,
		active = true
	}

	SendReactMessage('setPrompt', prompt)

	return id
end

---@param id? string
---@return boolean
local function hidePrompt(id)
	if id and id ~= prompt.id then return false end

	prompt.active = false
	SendReactMessage('setPromptVisible', false)

	return true
end

---@return string | nil
local function getPrompt()
	if not prompt.active then return end

	return prompt.id
end

---@param data { id?: string, text: string, control: string, hold?: boolean, controlId: number, timeout?: number }
lib.callback.register('requestPrompt', function(data)
	local hidden = hidePrompt()
	if hidden then
		Wait(100)
	end

	showPrompt(data.id, data.text, data.control or 'E', data.hold)

	local timer = GetGameTimer() + (data.timeout or 5000)

	while timer > GetGameTimer() do
		Wait(0)

		if IsControlJustReleased(0, data.controlId or 38) then
			hidePrompt()
			return true
		end
	end

	hidePrompt()
	return false
end)

RegisterNetEvent('showPrompt', showPrompt)
RegisterNetEvent('hidePrompt', hidePrompt)

lib.callback.register('getPrompt', getPrompt)

convertExport('getPrompt', getPrompt)

convertExport('showPrompt', function(...)
	local args = {...}

	-- Backwards compatibility
	if type(args[1]) == 'table' then
		return showPrompt(args[1].text, args[1].text, args[1].pressText, args[1].hold)
	end

	return showPrompt(...)
end)

convertExport('hidePrompt', hidePrompt)