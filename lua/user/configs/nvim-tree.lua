local function on_attach(bufnr)
	local api = require("nvim-tree.api")
	api.config.mappings.default_on_attach(bufnr)
	pcall(vim.keymap.del, "n", "<C-e>", { buffer = bufnr })
end

return {
	respect_buf_cwd = false,
	sync_root_with_cwd = true,
	update_focused_file = {
		enable = true,
		update_root = {
			enable = false,
		},
	},
	on_attach = on_attach,
}
