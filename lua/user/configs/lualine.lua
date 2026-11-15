return function(opts)
	local icons = {
		ui = require("modules.utils.icons").get("ui", true),
	}

	opts.options.theme = "auto"

	-- Use empty separator instead of vertical bar "│"
	if opts.sections and opts.sections.lualine_b and opts.sections.lualine_b[3] then
		opts.sections.lualine_b[3][1] = function()
			return ""
		end
	end
	if opts.sections and opts.sections.lualine_y and opts.sections.lualine_y[1] then
		opts.sections.lualine_y[1][1] = function()
			return ""
		end
	end

	-- Display buffer shiftwidth instead of tabstop
	if opts.sections and opts.sections.lualine_x and opts.sections.lualine_x[4] then
		opts.sections.lualine_x[4][1] = function()
			return icons.ui.Tab .. vim.bo.shiftwidth
		end
	end

	-- Restore compact sidebar/panel statuslines (upstream emptied `extensions` for disabled `edgy.nvim`)
	local mini_sections = {
		lualine_a = { "filetype" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	}
	opts.extensions = {
		"quickfix",
		"nvim-tree",
		"nvim-dap-ui",
		"toggleterm",
		"fugitive",
		"trouble",
		{
			sections = mini_sections,
			filetypes = { "Outline", "lspsagaoutline" },
		},
		{
			sections = mini_sections,
			filetypes = { "DiffviewFiles" },
		},
	}

	return opts
end
