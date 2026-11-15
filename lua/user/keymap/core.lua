local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_cmd = bind.map_cmd

return {
	-- Terminal window navigation
	["t|<C-h>"] = map_cmd("<Cmd>wincmd h<CR>"):with_silent():with_noremap():with_desc("window: Focus left"),
	["t|<C-l>"] = map_cmd("<Cmd>wincmd l<CR>"):with_silent():with_noremap():with_desc("window: Focus right"),
	["t|<C-j>"] = map_cmd("<Cmd>wincmd j<CR>"):with_silent():with_noremap():with_desc("window: Focus down"),
	["t|<C-k>"] = map_cmd("<Cmd>wincmd k<CR>"):with_silent():with_noremap():with_desc("window: Focus up"),

	-- Window resize
	["n|<A-[>"] = map_cr("vertical resize -5"):with_silent():with_noremap():with_desc("window: Resize -5 vertically"),
	["n|<A-]>"] = map_cr("vertical resize +5"):with_silent():with_noremap():with_desc("window: Resize +5 vertically"),
	["n|<A-;>"] = map_cr("resize -2"):with_silent():with_noremap():with_desc("window: Resize -2 horizontally"),
	["n|<A-'>"] = map_cr("resize +2"):with_silent():with_noremap():with_desc("window: Resize +2 horizontally"),

	-- Unbind upstream smart-splits resize keys
	["n|<A-h>"] = "",
	["n|<A-l>"] = "",
}
