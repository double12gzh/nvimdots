local MAX_TS_FOLD_LINES = 10000
local MAX_TS_FOLD_BYTES = 512 * 1024
local TS_FOLDEXPR = "v:lua.vim.treesitter.foldexpr()"

---@param buf integer
---@return boolean
local function should_enable_ts_fold(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
		return false
	end
	if vim.bo[buf].buftype ~= "" then
		return false
	end
	local ft = vim.bo[buf].filetype
	if ft == "" then
		return false
	end
	local line_count = vim.api.nvim_buf_line_count(buf)
	if line_count > MAX_TS_FOLD_LINES then
		return false
	end
	local ok_offset, byte_size = pcall(vim.api.nvim_buf_get_offset, buf, line_count)
	if not ok_offset or type(byte_size) ~= "number" or byte_size < 0 or byte_size > MAX_TS_FOLD_BYTES then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	if name ~= "" then
		local stat = vim.uv.fs_stat(name)
		if stat and stat.size > MAX_TS_FOLD_BYTES then
			return false
		end
	end
	local lang = vim.treesitter.language.get_lang(ft) or ft
	local ok_lang, added = pcall(vim.treesitter.language.add, lang)
	return ok_lang and added == true
end

---@param win integer
local function enable_ts_fold(win)
	vim.wo[win][0].foldmethod = "expr"
	vim.wo[win][0].foldexpr = TS_FOLDEXPR
end

---@param win integer
---@param buf integer
local function clear_stale_ts_fold(win, buf)
	if vim.bo[buf].buftype == "" and vim.wo[win].foldmethod == "expr" and vim.wo[win].foldexpr == TS_FOLDEXPR then
		vim.wo[win][0].foldmethod = "manual"
		vim.wo[win][0].foldexpr = "0"
	end
end

local ts_fold_group = vim.api.nvim_create_augroup("UserTreesitterFold", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = ts_fold_group,
	callback = function(args)
		if should_enable_ts_fold(args.buf) then
			for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
				enable_ts_fold(win)
			end
		else
			for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
				clear_stale_ts_fold(win, args.buf)
			end
		end
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = ts_fold_group,
	callback = function(args)
		local win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_buf(win) ~= args.buf then
			return
		end
		if should_enable_ts_fold(args.buf) then
			enable_ts_fold(win)
			if not vim.b[args.buf]._ts_fold_zx_done then
				vim.b[args.buf]._ts_fold_zx_done = true
				pcall(vim.cmd, "silent! normal! zx")
			end
		else
			clear_stale_ts_fold(win, args.buf)
		end
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
