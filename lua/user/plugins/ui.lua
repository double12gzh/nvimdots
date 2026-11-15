local ui = {}

ui["sainnhe/gruvbox-material"] = {
	lazy = false,
	priority = 1000,
	init = function()
		require("user.configs.gruvbox-material")
	end,
}

ui["Jint-lzxy/nvim"] = {
	lazy = true,
}

ui["mrjones2014/smart-splits.nvim"] = {
	cmd = {
		"SmartCursorMoveLeft",
		"SmartCursorMoveDown",
		"SmartCursorMoveUp",
		"SmartCursorMoveRight",
		"SmartResizeLeft",
		"SmartResizeDown",
		"SmartResizeUp",
		"SmartResizeRight",
		"SmartSwapLeft",
		"SmartSwapDown",
		"SmartSwapUp",
		"SmartSwapRight",
	},
}

return ui
