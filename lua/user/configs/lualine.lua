return function(opts)
	local icons = {
		ui = require("modules.utils.icons").get("ui", true),
	}

	opts.options.theme = "auto"

	---Check whether the current buffer belongs to a Git repo or worktree,
	---using gitsigns buffer vars first and falling back to a per-buffer cache.
	---@return boolean
	local function has_git()
		if vim.b.gitsigns_head ~= nil or vim.b.gitsigns_status_dict ~= nil then
			return true
		end
		local bufname = vim.api.nvim_buf_get_name(0)
		local cwd = vim.uv.cwd()
		local cached = vim.b._user_has_git
		if type(cached) == "table" and cached.bufname == bufname and cached.cwd == cwd then
			return cached.has_git
		end
		local path = bufname ~= "" and vim.fs.dirname(bufname) or cwd
		local found = path ~= nil and path ~= "" and #vim.fs.find(".git", { limit = 1, upward = true, path = path }) > 0
		vim.b._user_has_git = {
			bufname = bufname,
			cwd = cwd,
			has_git = found,
		}
		return found
	end

	-- Use empty separator instead of vertical bar "│" and cache git checks
	if opts.sections and opts.sections.lualine_b and opts.sections.lualine_b[3] then
		opts.sections.lualine_b[3][1] = function()
			return ""
		end
		opts.sections.lualine_b[3].cond = function()
			return has_git() and vim.bo.filetype ~= ""
		end
	end
	if opts.sections and opts.sections.lualine_c then
		if opts.sections.lualine_c[1] then
			opts.sections.lualine_c[1].cond = has_git
		end
		if opts.sections.lualine_c[2] then
			opts.sections.lualine_c[2].cond = has_git
		end
	end
	if opts.sections and opts.sections.lualine_y and opts.sections.lualine_y[1] then
		opts.sections.lualine_y[1][1] = function()
			return ""
		end
	end

	local ok_cc, cc_status = pcall(require, "cc_workspace.statusline")
	local cc_comp = ok_cc and cc_status.component() or nil
	if cc_comp and opts.sections and opts.sections.lualine_x then
		opts.sections.lualine_x[1] = cc_comp
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
	if ok_cc and cc_comp then
		table.insert(opts.extensions, cc_status.extension(cc_comp))
	end

	return opts
end
