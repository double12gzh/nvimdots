local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_cu = bind.map_cu
local map_callback = bind.map_callback

local plug_map = {
	["n|<F2>"] = map_cr("NvimTreeToggle"):with_noremap():with_silent():with_desc("filetree: Toggle"),
	["n|<leader>fs"] = map_cu("Telescope grep_string")
		:with_noremap()
		:with_silent()
		:with_desc("tool: Find word under cursor"),
	["n|<leader>fw"] = map_callback(function()
			require("telescope").extensions.live_grep_args.live_grep_args()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("find: Word in project"),
}

return plug_map
