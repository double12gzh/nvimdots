-- Please check `lua/core/settings.lua` to view the full list of configurable settings
local settings = {}

settings["use_ssh"] = true
settings["use_copilot"] = true
settings["edit_prediction_source"] = "copilot"

settings["colorscheme"] = "gruvbox-material"
settings["diagnostics_virtual_lines"] = false
settings["diagnostics_level"] = "HINT"

settings["format_disabled_dirs"] = function()
	local home = require("core.global").home
	return {
		home .. "/format_disabled_dir",
	}
end

settings["disabled_plugins"] = function()
	return {
		"tpope/vim-sleuth",
		"Bekaboo/dropbar.nvim",
		"folke/edgy.nvim",
		"karb94/neoscroll.nvim",
		"rachartier/tiny-inline-diagnostic.nvim",
	}
end

settings["server_formatting_block_list"] = {
	clangd = true,
	lua_ls = true,
	ts_ls = true,
	html = true,
	yamlls = true,
	ruff = false,
}

settings["null_ls_deps"] = function()
	return {
		"clang_format",
		"goimports",
		"prettier",
		"shfmt",
		"stylua",
		"vint",
	}
end

settings["lsp_deps"] = function()
	return {
		"bashls",
		"clangd",
		"gopls",
		"html",
		"jsonls",
		"lua_ls",
		"pylsp",
		"rust_analyzer",
		"yamlls",
	}
end

settings["dashboard_image"] = function()
	return {
		[[   ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⣶⣶⣶⣶⣶⠶⣶⣤⣤⣀⠀⠀⠀    ]],
		[[ ⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⠁⠀⢀⠈⢿⢀⣀⠀⠹⣿⣿⣿⣦⣄⠀⠀⠀ ]],
		[[ ⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⠿⠀⠀⣟⡇⢘⣾⣽⠀⠀⡏⠉⠙⢛⣿⣷⡖⠀ ]],
		[[ ⠀⠀⠀⠀⠀⣾⣿⣿⡿⠿⠷⠶⠤⠙⠒⠀⠒⢻⣿⣿⡷⠋⠀⠴⠞⠋⠁⢙⣿⣄ ]],
		[[ ⠀⠀⠀⠀⢸⣿⣿⣯⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠉⢹⡄⠀⠀⠀⠛⠛⠋⠉⠹⡇ ]],
		[[ ⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⣀⣠⣤⣤⣤⣤⣤⣤⣤⣼⣇⣀⣀⣀⣛⣛⣒⣲⢾⡷ ]],
		[[ ⢀⠤⠒⠒⢼⣿⣿⠶⠞⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⣼⠃ ]],
		[[ ⢮⠀⠀⠀⠀⣿⣿⣆⠀⠀⠻⣿⡿⠛⠉⠉⠁⠀⠉⠉⠛⠿⣿⣿⠟⠁⠀⣼⠃⠀ ]],
		[[ ⠈⠓⠶⣶⣾⣿⣿⣿⣧⡀⠀⠈⠒⢤⣀⣀⡀⠀⠀⣀⣀⡠⠚⠁⠀⢀⡼⠃⠀⠀ ]],
		[[ ⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣭⣭⣭⣭⣭⣥⣤⣤⣤⣴⣟⠁    ]],
	}
end

return settings
