-- Refresh Treesitter expr folds when opening buffers (e.g. via Telescope)
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("UserTreesitterFoldFix", { clear = true }),
	callback = function()
		vim.api.nvim_create_autocmd("BufWinEnter", {
			once = true,
			callback = function()
				if vim.wo.foldmethod == "expr" then
					pcall(vim.cmd, "silent! normal! zx")
				end
			end,
		})
	end,
})

local definitions = {
	ft = function()
		return {
			{ "FileType", "*", "setlocal formatoptions-=cro" },
			{ "FileType", "alpha", "setlocal showtabline=0" },
			{ "FileType", "markdown", "setlocal wrap" },
			{ "FileType", "dap-repl", "lua require('dap.ext.autocompl').attach()" },
			{
				"FileType",
				"c,cpp",
				"nnoremap <silent> <buffer> <leader>h <Cmd>LspClangdSwitchSourceHeaderVsplit<CR>",
			},
		}
	end,
}

return definitions
