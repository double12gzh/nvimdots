local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_callback = bind.map_callback
local helpers = require("keymap.helpers")

local mappings = {}

mappings["plug_map"] = {}

---@param buf integer
mappings["lsp"] = function(buf)
	-- Upstream `lua/keymap/completion.lua` omits `:with_buffer(buf)` on these 5 keys,
	-- leaking them globally on every LspAttach (including crashing `<leader>lv`).
	for _, lhs in ipairs({ "gs", "gh", "gm", "<leader>lv", "<leader>lh" }) do
		pcall(vim.keymap.del, "n", lhs)
	end

	-- Remove upstream buffer-local keys that differ from user habits on `buf`.
	for _, lhs in ipairs({ "go", "gto", "<leader>lx", "gci", "gco" }) do
		pcall(vim.keymap.del, "n", lhs, { buffer = buf })
	end

	-- Load buffer-local mappings directly on `buf` and return `{}` so upstream
	-- `keymap.replace` (which hardcodes buffer `0` instead of `buf`) never wipes
	-- LSP mappings from other open split buffers.
	bind.nvim_load_mapping({
		["n|<F3>"] = map_cr("Lspsaga outline"):with_silent():with_buffer(buf):with_desc("lsp: Toggle outline"),
		["n|gd"] = map_cr("Lspsaga goto_definition"):with_silent():with_buffer(buf):with_desc("lsp: Goto definition"),
		["n|gD"] = map_cr("Lspsaga peek_definition")
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Preview definition"),
		["n|gh"] = map_cr("Lspsaga finder def+ref+imp"):with_silent():with_buffer(buf):with_desc("lsp: Show reference"),
		["n|gs"] = map_callback(function()
				vim.lsp.buf.signature_help()
			end)
			:with_noremap()
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Signature help"),
		["n|<leader>ld"] = map_cr("Lspsaga show_line_diagnostics ++unfocus")
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Line diagnostic"),
		["n|<leader>ci"] = map_cr("Lspsaga incoming_calls")
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Show incoming calls"),
		["n|<leader>co"] = map_cr("Lspsaga outgoing_calls")
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Show outgoing calls"),
		["n|<leader>lh"] = map_callback(function()
				helpers.toggle_inlayhint()
			end)
			:with_noremap()
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Toggle inlay hints"),
		["n|<leader>lv"] = map_callback(function()
				local current = vim.diagnostic.config().virtual_text
				if current then
					vim.diagnostic.config({ virtual_text = false })
					vim.notify("Virtual text diagnostics hidden", vim.log.levels.INFO, { title = "LSP Diagnostic" })
				else
					local level = require("core.settings").diagnostics_level or "HINT"
					vim.diagnostic.config({
						virtual_text = {
							severity = {
								min = vim.diagnostic.severity[level:upper()] or vim.diagnostic.severity.HINT,
							},
						},
					})
					vim.notify("Virtual text diagnostics displayed", vim.log.levels.INFO, { title = "LSP Diagnostic" })
				end
			end)
			:with_noremap()
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Toggle virtual text"),
	})

	return {}
end

return mappings
