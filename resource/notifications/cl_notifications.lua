local colors = {
	red = '#FC5656',
	blue = '#3AE2EE',
	yellow = '#FFF500',
	error = '#FC5656',
	success = '#3AE2EE',
	inform = '#FFF500',
}

---@param title string e.g. "Blueberries Consumed"
---@param desc string e.g. "You consumed awesome blueberries, enjoy the +100 hunger and +100 armor"
---@param duration number e.g. 5000
---@param icon string e.g. "blueberries"
---@param color string e.g. "#3AE2EE" or "blue"
---@param persistent? string can be considered an ID, like "iDScan"
local function sendNotification(title, desc, duration, icon, color, persistent)
	SendReactMessage('notification', {
		title = title,
		description = desc,
		duration = duration or 5000,
		icon = icon,
		color = color and colors[color] or color,
		id = persistent -- If an ID is passed, the notification will be persistent
	})
end

---@param persistent string can be considered an ID, like "iDScan"
local function removeNotification(persistent)
	if not persistent then return end
	SendReactMessage('removeNotification', persistent)
end

RegisterNetEvent('sendNotification', function(data)
	sendNotification(data.title, data.desc or data.text, data.duration or data.length, data.icon, data.color or data.type or data.style, data.id)
end)

RegisterNetEvent('erp_notifications:client:SendAlert', function(data)
	sendNotification(data.title, data.desc or data.text, data.duration or data.length, data.icon, data.color or data.type or data.style, data.id)
end)

RegisterNetEvent('removeNotification', removeNotification)

convertExport('sendAlert', function(color, desc, length)
	sendNotification('', desc, length, '', color)
end)

convertExport('SendAlert', function(color, desc, length)
	sendNotification('', desc, length, '', color)
end)

convertExport('sendNotification', sendNotification)
convertExport('removeNotification', removeNotification)