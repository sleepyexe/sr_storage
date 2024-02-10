fx_version 'cerulean'
game 'gta5'

name "sr_storage"
description "Player Owned Storage With Rent System"
author "Sleepy Rae"
version "1.0.0"
lua54 'yes'

files {
	'data/*.lua'
}

shared_scripts {
	'@ox_lib/init.lua',
	'@es_extended/imports.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}


dependencies {
	'ox_lib',
	'es_extended',
	'ox_target',
	'ox_inventory',	
}