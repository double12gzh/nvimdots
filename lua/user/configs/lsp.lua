local settings = require("core.settings")
local level = settings.diagnostics_level or "HINT"

-- Re-enable permanent virtual_text diagnostics after mason-lspconfig sets virtual_text = false
vim.diagnostic.config({
	signs = true,
	underline = true,
	virtual_text = {
		severity = {
			min = vim.diagnostic.severity[level:upper()] or vim.diagnostic.severity.HINT,
		},
	},
	update_in_insert = false,
})

-- Disable Mason packages that mason-registry maps to lspconfig (e.g. stylua 0.x)
-- when they are only installed as formatters/linters and not listed in `lsp_deps`.
local lsp_deps = settings.lsp_deps or {}
for name, _ in pairs(vim.lsp._enabled_configs or {}) do
	if not vim.list_contains(lsp_deps, name) and name ~= "dartls" then
		vim.lsp.enable(name, false)
	end
end

-- Neovim 0.12 has built-in `:lsp`, so nvim-lspconfig skips creating legacy `:Lsp*` commands.
-- Provide compatibility user commands so `<leader>li`, `<leader>lr`, and muscle-memory `:Lsp*` work
-- without triggering `:lsp enable` interactive prompts when called with no arguments.
if vim.fn.exists(":LspInfo") ~= 2 then
	vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", { desc = "Show LSP client health/info" })
end

if vim.fn.exists(":LspLog") ~= 2 then
	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd(string.format("tabnew %s", vim.lsp.log.get_filename()))
	end, { desc = "Open Nvim LSP client log" })
end

if vim.fn.exists(":LspRestart") ~= 2 then
	vim.api.nvim_create_user_command("LspRestart", function(info)
		if #info.fargs > 0 then
			vim.cmd("lsp restart " .. table.concat(info.fargs, " "))
		else
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				vim.cmd("lsp restart " .. client.name)
			end
		end
	end, { nargs = "*", desc = "Restart LSP client(s)" })
end

if vim.fn.exists(":LspStart") ~= 2 then
	vim.api.nvim_create_user_command("LspStart", function(info)
		if #info.fargs > 0 then
			vim.lsp.enable(info.fargs)
			return
		end
		local ft = vim.bo.filetype
		if ft == "" then
			return
		end
		local cfg_tbl = vim.lsp.config._configs or {}
		for name, _ in pairs(cfg_tbl) do
			if vim.list_contains(lsp_deps, name) or name == "dartls" then
				local cfg = vim.lsp.config[name]
				if cfg and cfg.filetypes and vim.list_contains(cfg.filetypes, ft) then
					vim.lsp.enable(name)
				end
			end
		end
	end, { nargs = "*", desc = "Enable/start LSP server(s) for current filetype" })
end

if vim.fn.exists(":LspStop") ~= 2 then
	vim.api.nvim_create_user_command("LspStop", function(info)
		if #info.fargs > 0 then
			vim.cmd("lsp stop " .. table.concat(info.fargs, " "))
		else
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				client:stop()
			end
		end
	end, { nargs = "*", desc = "Stop LSP client(s)" })
end

-- Compatibility command aliases for muscle memory
if vim.fn.exists(":SymbolsOutline") ~= 2 then
	vim.api.nvim_create_user_command("SymbolsOutline", function()
		vim.cmd("Lspsaga outline")
	end, { desc = "Toggle LSP symbols outline via Lspsaga" })
end

if vim.fn.exists(":ClangdSwitchSourceHeaderVSplit") ~= 2 then
	vim.api.nvim_create_user_command("ClangdSwitchSourceHeaderVSplit", function()
		vim.cmd("LspClangdSwitchSourceHeaderVsplit")
	end, { desc = "Open C/C++ source/header in vsplit" })
end

if vim.fn.exists(":ClangdSwitchSourceHeader") ~= 2 then
	vim.api.nvim_create_user_command("ClangdSwitchSourceHeader", function()
		vim.cmd("LspClangdSwitchSourceHeader")
	end, { desc = "Switch C/C++ source/header" })
end
