local bind = require("keymap.bind")
local map_cr = bind.map_cr

return {
	-- Plugin: bufferline.nvim
	["n|<A-k>"] = map_cr("BufferLineCycleNext"):with_noremap():with_silent():with_desc("buffer: Switch to next"),
	["n|<A-j>"] = map_cr("BufferLineCyclePrev"):with_noremap():with_silent():with_desc("buffer: Switch to prev"),
	["n|<A-S-k>"] = map_cr("BufferLineMoveNext"):with_noremap():with_silent():with_desc("buffer: Move current to next"),
	["n|<A-S-j>"] = map_cr("BufferLineMovePrev"):with_noremap():with_silent():with_desc("buffer: Move current to prev"),

	-- Unbind upstream bufferline cycle/move keys
	["n|<A-i>"] = "",
	["n|<A-o>"] = "",
	["n|<A-S-i>"] = "",
	["n|<A-S-o>"] = "",
}
