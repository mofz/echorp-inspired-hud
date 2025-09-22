fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
name 'echo_interface'
description 'EchoRP Inspired UI Resource'
version '1.0.0'
author 'Axo'

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'resource/**/sh_*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
'resource/**/sv_*.lua',
}

client_scripts {
    'resource/**/cl_*.lua'
}

files {
	'web/build/index.html',
	'web/build/**/*',
	'stream/*.gfx'
}

data_file "SCALEFORM_DLC_FILE" "stream/*.gfx"

provide 'erp_notifications'

provide 'erp_prompts'
