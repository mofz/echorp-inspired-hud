local resources = {
	'erp_hud',
	'erp_notifications',
	'erp_prompts',
	'erp_dialog'
}

function convertExport(export, func)
	for i=1, #resources do
		local event = ('__cfx_export_%s_%s'):format(resources[i], export)
		AddEventHandler(event, function(cb)
			cb(func)
		end)

		print('^2Backwards compatibility export created ^7'..event)
	end

    exports(export, func)
end