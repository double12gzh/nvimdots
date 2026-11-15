local global = require("core.global")
global.proxy_nvim = os.getenv("PROXY_NVIM") or "http://127.0.0.1:7890"

local level = require("core.settings").diagnostics_level or "HINT"
vim.diagnostic.config({
	signs = true,
	underline = true,
	virtual_text = {
		severity = {
			min = vim.diagnostic.severity[level:upper()] or vim.diagnostic.severity.HINT,
		},
	},
	update_in_insert = false,
})

local options = {
	cursorcolumn = false,
	relativenumber = false,
	wrap = true,
	textwidth = 0,
	smoothscroll = false,
	scrolloff = 2,
	writebackup = false,
	jumpoptions = "stack",
}

return options
