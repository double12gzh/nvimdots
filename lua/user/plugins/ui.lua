local ui = {}

ui["sainnhe/gruvbox-material"] = {
	lazy = true,
	--event = "VimEnter",
	config = function()
		require("ui.gruvbox-material")
	end,
}

return ui
