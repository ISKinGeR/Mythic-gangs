fx_version 'cerulean'
game 'gta5'

dependency 'sprays'
server_script "@oxmysql/lib/MySQL.lua"

shared_scripts {
    'shared/sh_*.lua',
}

client_scripts {
    'client/*',
}

server_scripts {
    'server/*',
}

lua54 'yes'