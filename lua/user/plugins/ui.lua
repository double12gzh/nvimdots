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

ui["goolord/alpha-nvim"] = {
	event = function()
		return vim.fn.argc(-1) == 0 and { "BufWinEnter" } or {}
	end,
	cmd = "Alpha",
}

ui["mrjones2014/smart-splits.nvim"] = {
	event = false,
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

ui["lewis6991/gitsigns.nvim"] = {
	event = function()
		return { "BufReadPre", "BufNewFile" }
	end,
}

ui["lukas-reineke/indent-blankline.nvim"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
}

ui["folke/todo-comments.nvim"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
	cmd = {
		"TodoTrouble",
		"TodoTelescope",
		"TodoQuickFix",
		"TodoLocList",
	},
}

return ui
