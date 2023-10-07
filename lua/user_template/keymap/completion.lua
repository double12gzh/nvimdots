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
		-- quick --
		["n|gD"] = map_cr("Lspsaga peek_definition"):with_buffer(buf):with_desc("lsp: Preview definition"),
		["n|gd"] = map_cr("Lspsaga goto_definition"):with_buffer(buf):with_desc("lsp: Goto definition"),
		["n|gh"] = map_cr("Lspsaga finder ref"):with_buffer(buf):with_desc("lsp: Show reference"),
		["n|gi"] = map_cr("Lspsaga finder imp"):with_buffer(buf):with_desc("lsp: Show reference"),
		--["n|gD"] = map_cr("Glance definitions"):with_buffer(buf):with_desc("lsp: Preview definition"),
		--["n|gd"] = map_cr("Glance definitions"):with_buffer(buf):with_desc("lsp: Show reference"),
		--["n|gh"] = map_cr("Glance references"):with_buffer(buf):with_desc("lsp: Show reference"),
		--["n|gi"] = map_cr("Glance implementations"):with_buffer(buf):with_desc("lsp: Show reference"),
		-- quick --
	}
end

return mappings
