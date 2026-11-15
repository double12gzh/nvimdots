local editor = {}

editor["max397574/better-escape.nvim"] = {
	lazy = true,
	event = function()
		return { "InsertEnter" }
	end,
	config = function()
		require("user.configs.better-escape")()
	end,
}

editor["smoka7/hop.nvim"] = {
	event = false,
	cmd = {
		"HopWord",
		"HopLine",
		"HopChar1",
		"HopChar2",
		"HopWordMW",
		"HopLineMW",
		"HopChar1MW",
		"HopChar2MW",
	},
}

editor["folke/flash.nvim"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
}

editor["numToStr/Comment.nvim"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
}

editor["echasnovski/mini.align"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
}

editor["brenoprata10/nvim-highlight-colors"] = {
	event = function()
		return { "BufReadPost", "BufNewFile" }
	end,
}

editor["romainl/vim-cool"] = {
	event = function()
		return { "BufReadPost", "BufNewFile", "InsertEnter" }
	end,
}

editor["nvim-treesitter/nvim-treesitter"] = {
	lazy = true,
	event = function()
		return { "BufReadPre", "BufNewFile" }
	end,
	cmd = {
		"TSInstall",
		"TSUpdate",
		"TSUninstall",
		"TSLog",
	},
}

return editor
