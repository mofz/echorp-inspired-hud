local threadActive = false -- Whether or not the button detection thread is active

local menus = {} -- Stored menus for instructional
local cachedButtons = {} -- Buttons to listen out for
local buttonStates = {}

---This function highlights a button in the instructional buttons.
---This is useful for when you want to highlight a button when a certain condition is met.
---@param code number
---@param state boolean Whether to highlight the button or not
local function highlightButton(code, state)
	SendReactMessage('highlightInstructionalButton', { code = code, state = state })
end

local function buttonListener(button)
	if not button then return end

	local code <const> = button.code
	if not code then return end

	if not buttonStates[code] then
		buttonStates[code] = { pressed = false }
	end

	if IsDisabledControlPressed(0, code) then
		if button.onPress then
			CreateThread(button.onPress)
		end

		if not buttonStates[code].pressed then
			buttonStates[code].pressed = true

			highlightButton(code, true)

			if button.onTap then
				CreateThread(button.onTap)
			end
		end
	end

	if buttonStates[code].pressed and IsDisabledControlReleased(0, code) then
		buttonStates[code].pressed = false

		highlightButton(code, false)

		if button.onRelease then
			button.onRelease()
		end
	end

end

local function buttonsListener()
	if threadActive then return end
	threadActive = true

	CreateThread(function()
		while threadActive do
            Wait(0)

			local size = #cachedButtons
			if size == 0 then
				threadActive = false
				goto skip
			end

			for i=1, size do
				buttonListener(cachedButtons[i])
			end

			::skip::
        end
	end)
end

---@param id string
---@param buttons table
local function addButtonsListener(id, buttons)
	if not buttons then return end

	for i=1, #buttons do
		local button <const> = buttons[i]
		table.insert(cachedButtons, { id = id, code = button.code, onTap = button.onTap, onPress = button.onPress, onRelease = button.onRelease })
	end
end

---@param id string
local function removeButtonsListener(id)
	if not id then return end

	for i=#cachedButtons, 1, -1 do
		if cachedButtons[i].id == id then
			table.remove(cachedButtons, i)
		end
	end
end

---@param id string
---@param buttons table
---@param visible boolean?
---@param resource string? Optional resource param
local function createInstructionalMenu(id, buttons, visible, resource)
	if visible == nil then visible = true end

	if not resource then
		resource = GetInvokingResource()
	end

	local menu <const> = { id = id, visible = visible, buttons = buttons, resource = resource }
	table.insert(menus, menu)

	local filteredButtons = {}

	for i=1, #buttons do
		local button = buttons[i]
		table.insert(filteredButtons, { key = button.key, label = button.label, code = button.code })
	end

	Wait(0)

	SendReactMessage('addInstructionalMenu', { id = id, visible = visible, buttons = filteredButtons })

	if not visible then return end

	addButtonsListener(id, menu.buttons)
	buttonsListener()
end

---@param id string
---@param visible boolean?
local function toggleInstructionalMenu(id, visible)
	local menu

	for i=1, #menus do
		if menus[i].id == id then
			menu = menus[i]
			break
		end
	end

	if not menu then
		return print('unable to toggle instructional menu', id)
	end

	if visible == nil then
		visible = not menu.visible
	else
		visible = visible or false
	end

	if menu.visible == visible then return end
	menu.visible = visible

	SendReactMessage('toggleInstructionalMenu', { id = id, visible = menu.visible })

	if visible then
		addButtonsListener(id, menu.buttons)
	else
		removeButtonsListener(id)
	end

	buttonsListener()
end

---@param id string
local function removeInstructionalMenu(id)
	for i=1, #menus do
		if menus[i].id == id then
			table.remove(menus, i)

			removeButtonsListener(id)
			buttonsListener()

			Wait(0)

			SendReactMessage('removeInstructionalMenu', id)
			return
		end
	end
end

AddEventHandler("onResourceStop", function(resourceName)
	for i=#menus, 1, -1 do
		if menus[i].resource == resourceName then
			removeInstructionalMenu(menus[i].id)
		end
	end
end)

exports('createInstructionalMenu', createInstructionalMenu)
exports('toggleInstructionalMenu', toggleInstructionalMenu)
exports('removeInstructionalMenu', removeInstructionalMenu)