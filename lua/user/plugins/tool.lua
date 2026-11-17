local tool = {}
local settings = require("core.settings")

if settings.use_chat then
	local cc_ws_dir = vim.fn.expand("~/Documents/code/cc-workspace.nvim")

	tool["double12gzh/cc-workspace.nvim"] = {
		dir = vim.uv.fs_stat(cc_ws_dir) and cc_ws_dir or nil,
		main = "cc_workspace",
		lazy = true,
		cmd = {
			"CodeCompanionWorkspace",
			"CodeCompanionWorkspaceAddProject",
			"CodeCompanionWorkspaceWorktree",
			"CodeCompanionWorkspaceKeys",
			"CodeCompanionNotificationsToggle",
		},
		opts = {},
	}

	tool["olimorris/codecompanion.nvim"] = {
		pin = true,
		dependencies = {
			"double12gzh/cc-workspace.nvim",
		},
	}

	tool["ravitemer/codecompanion-history.nvim"] = {
		pin = true,
	}
end

return tool
