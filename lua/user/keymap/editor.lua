local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_cmd = bind.map_cmd

return {
	-- Unbind upstream `;` override so native `;`/`,` and flash.nvim char repeat work
	["nxo|;"] = "",

	-- Plugin: hop.nvim
	["nv|<leader>cc"] = map_cmd("<Cmd>HopChar2MW<CR>"):with_noremap():with_desc("jump: Goto two chars"),
	["nv|<leader>C"] = "",

	-- Plugin: diffview.nvim
	["n|<leader>D"] = map_cr("DiffviewOpen"):with_silent():with_noremap():with_desc("git: Show diff"),
	["n|<leader><leader>D"] = map_cr("DiffviewClose"):with_silent():with_noremap():with_desc("git: Close diff"),
	["n|<leader>gd"] = "",
	["n|<leader>gD"] = "",
}
