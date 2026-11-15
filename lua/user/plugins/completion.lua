local completion = {}

completion["mason-org/mason.nvim"] = {
	cmd = function()
		return {
			"Mason",
			"MasonInstall",
			"MasonInstallAll",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonUpdate",
			"MasonLog",
		}
	end,
}

completion["neovim/nvim-lspconfig"] = {
	event = function()
		return { "BufReadPre", "BufNewFile" }
	end,
}

completion["nvimtools/none-ls.nvim"] = {
	event = function()
		return { "BufReadPre", "BufNewFile" }
	end,
	cmd = {
		"Format",
		"FormatToggle",
		"FormatterToggleFt",
		"NullLsToggle",
	},
	dependencies = {
		"mason-org/mason.nvim",
	},
}

completion["saghen/blink.cmp"] = {
	event = function()
		return { "InsertEnter", "CmdlineEnter" }
	end,
}

completion["zbirenbaum/copilot.lua"] = {
	event = function()
		return { "InsertEnter" }
	end,
	cmd = "Copilot",
}

return completion
