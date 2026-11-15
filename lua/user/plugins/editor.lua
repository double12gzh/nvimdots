local editor = {}

editor["max397574/better-escape.nvim"] = {
	lazy = true,
	event = { "InsertEnter", "CursorHold", "CursorHoldI" },
	config = function()
		require("user.configs.better-escape")()
	end,
}

editor["smoka7/hop.nvim"] = {
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

return editor
