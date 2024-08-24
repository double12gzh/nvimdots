local bind = require("keymap.bind")
local map_cr = bind.map_cr

local mappings = {}

-- Place global keymaps here.
mappings["plug_map"] = {}

-- NOTE: This function is special! Keymaps defined here are ONLY effective in buffers with LSP(s) attached
-- NOTE: Make sure to include `:with_buffer(buf)` to limit the scope of your mappings.
---@param buf number @The effective bufnr
mappings["lsp"] = function(buf)
	return {
		-- Example
		["n|K"] = map_cr("Lspsaga hover_doc"):with_buffer(buf):with_desc("lsp: Show doc"),
		["n|gD"] = map_cr("Glance definitions"):with_silent():with_buffer(buf):with_desc("lsp: Preview definition"),
		["n|gd"] = map_cr("Lspsaga goto_definition"):with_silent():with_buffer(buf):with_desc("lsp: Goto definition"),
		["n|<F3>"] = map_cr("AerialToggle!"):with_silent():with_buffer(buf):with_desc("lsp: Toggle outline"),
	}
end

return mappings
