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

completion["nvimtools/none-ls.nvim"] = {
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

return completion
