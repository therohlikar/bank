fx_version 'bodacious'
game 'gta5'

export "openBankMenu"
export "openCashMachine"
export "close"
export "openBankAccountList"

-- get/check
server_export "doesAccountExist"
server_export "getAccountVar"
server_export "getAccount"
server_export "getAccounts"
server_export "getAccessableAccounts"
server_export "isAccessableAccount"
server_export "isInAccessList"
server_export "getAccountJob"
-- set/add/delete
server_export "withdraw"
server_export "delete"
server_export "create"
server_export "addFunds"
server_export "checkFunds"
server_export "removeFunds"
server_export "transferFunds"
server_export "renameAccount"
server_export "addAccess"
server_export "removeAccess"
server_export "changeType"
server_export "changeOwner"
server_export "setPerms"
server_export "addCard"
server_export "removeCard"
server_export "blockCard"
server_export "renameCard"

client_scripts {
	"@menu/menu.lua",
	"config.lua",
	"client/main.lua"
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	"config.lua",
	"server/main.lua"
}

ui_page "html/ui.html"

files {
	"html/ui.html",
	"html/style.css",
	"html/fonts/gs.ttf",
	"html/listener.js"
}

