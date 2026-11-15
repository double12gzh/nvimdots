return {
	completion = {
		list = {
			selection = {
				preselect = true,
				auto_insert = false,
			},
		},
	},
	cmdline = {
		keymap = {
			preset = "cmdline",
			["<Left>"] = false,
			["<Right>"] = false,
			["<C-e>"] = false,
		},
		completion = {
			list = {
				selection = {
					preselect = false,
					auto_insert = true,
				},
			},
		},
	},
}
