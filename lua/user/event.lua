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

local function setup_auto_english_ime()
	local ime_cmd = vim.fn.executable("im-select") == 1 and "im-select"
		or (vim.fn.executable("macism") == 1 and "macism" or nil)
	if not ime_cmd then
		return
	end

	local abc_id = "com.apple.keylayout.ABC"
	local last_switch_ns = 0
	local function switch_to_abc(force)
		local now = vim.uv.hrtime()
		if not force and (now - last_switch_ns) < 120 * 1e6 then
			return
		end
		last_switch_ns = now
		pcall(vim.system, { ime_cmd, abc_id }, { detach = true })
	end

	local ime_group = vim.api.nvim_create_augroup("UserAutoEnglishIME", { clear = true })
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = ime_group,
		callback = function()
			switch_to_abc(true)
		end,
	})
	vim.api.nvim_create_autocmd({ "FocusGained", "WinEnter" }, {
		group = ime_group,
		callback = function()
			if vim.api.nvim_get_mode().mode:sub(1, 1) == "n" then
				switch_to_abc(false)
			end
		end,
	})
end

setup_auto_english_ime()

vim.api.nvim_create_user_command("UserInstallDeps", function()
	local script = vim.fn.stdpath("config") .. "/scripts/user-deps.sh"
	if vim.fn.filereadable(script) ~= 1 then
		vim.notify("Dependency script not found: " .. script, vim.log.levels.ERROR, { title = "UserDeps" })
		return
	end
	vim.cmd("botright 15split")
	vim.fn.termopen({ "bash", script })
	vim.cmd("startinsert")
end, { desc = "Install external user dependencies (e.g. im-select)" })

local definitions = {
	wins = function(wins)
		for _, item in ipairs(wins) do
			if item[1] == "VimResized" then
				item[3] =
					[[lua (function() local t, w, ei = vim.api.nvim_get_current_tabpage(), vim.api.nvim_get_current_win(), vim.o.eventignore; vim.o.eventignore = 'all'; pcall(vim.cmd, 'tabdo wincmd ='); if vim.api.nvim_tabpage_is_valid(t) then pcall(vim.api.nvim_set_current_tabpage, t) end; if vim.api.nvim_win_is_valid(w) then pcall(vim.api.nvim_set_current_win, w) end; vim.o.eventignore = ei; pcall(function() if package.loaded['cc_workspace'] then require('cc_workspace').sync_sidebar_width() end end) end)()]]
			end
		end
		return wins
	end,
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
