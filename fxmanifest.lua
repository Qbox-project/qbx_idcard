fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'qbx_idcard'
description 'Physical ID cards and licenses shown in hand'
version '1.0.0'

ui_page 'web/index.html'
nui_callback_strict_mode 'true'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
    'server/main.lua',
}

files {
    'configs/shared.lua',
    'configs/client.lua',
    'locales/*.json',
    'bridge/client.lua',
    'client/modules/*.lua',
    'web/index.html',
    'web/photo.js',
    'web/card.html',
    'web/card.css',
    'web/card.js',
    'web/fonts/*',
    'web/images/*.png',
    'stream/qbx_idcard.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/qbx_idcard.ytyp'

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'ox_inventory',
}
