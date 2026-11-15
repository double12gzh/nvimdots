-- Prevent mason-lspconfig from starting stylua as an LSP server (stylua 0.x lacks `--lsp`,
-- and Lua formatting is already handled via none-ls).
return {
	filetypes = {},
}
