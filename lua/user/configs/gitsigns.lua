local bind = require("keymap.bind")
local map_callback = bind.map_callback

return {
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")
		local map = {
			["n|]g"] = map_callback(function()
					if vim.wo.diff then
						return "]g"
					end
					vim.schedule(function()
						gitsigns.nav_hunk("next")
					end)
					return "<Ignore>"
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_expr()
				:with_desc("git: Goto next hunk"),
			["n|[g"] = map_callback(function()
					if vim.wo.diff then
						return "[g"
					end
					vim.schedule(function()
						gitsigns.nav_hunk("prev")
					end)
					return "<Ignore>"
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_expr()
				:with_desc("git: Goto prev hunk"),
			["n|<leader>hs"] = map_callback(function()
					gitsigns.stage_hunk()
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Stage hunk"),
			["v|<leader>hs"] = map_callback(function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Stage hunk"),
			["n|<leader>hu"] = map_callback(function()
					if gitsigns.undo_stage_hunk then
						gitsigns.undo_stage_hunk()
					else
						gitsigns.stage_hunk()
					end
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Undo stage hunk"),
			["n|<leader>hr"] = map_callback(function()
					gitsigns.reset_hunk()
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Reset hunk"),
			["v|<leader>hr"] = map_callback(function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Reset hunk"),
			["n|<leader>hR"] = map_callback(function()
					gitsigns.reset_buffer()
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Reset buffer"),
			["n|<leader>hp"] = map_callback(function()
					gitsigns.preview_hunk()
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Preview hunk"),
			["n|<leader>hb"] = map_callback(function()
					gitsigns.blame_line({ full = true })
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Blame line"),
			["ox|ih"] = map_callback(function()
					gitsigns.select_hunk()
				end)
				:with_buffer(bufnr)
				:with_noremap()
				:with_desc("git: Select hunk"),
		}
		bind.nvim_load_mapping(map)
	end,
}
