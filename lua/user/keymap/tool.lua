local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_cu = bind.map_cu
local map_cmd = bind.map_cmd
local map_callback = bind.map_callback
local helpers = require("keymap.helpers")

local function toggle_cli_agent(agent_name)
	local cc = require("codecompanion")
	local cli = require("codecompanion.interactions.cli")
	local existing = cli.find_by_agent(agent_name)
	if existing then
		if existing.ui:is_visible() then
			existing.ui:hide()
		else
			local visible = cli.get_visible()
			if visible and visible ~= existing then
				visible.ui:hide()
			end
			existing.ui:open()
			existing:focus()
		end
	else
		local visible = cli.get_visible()
		if visible then
			visible.ui:hide()
		end
		cc.cli({ agent = agent_name })
	end
end

---Extract a short preview of the latest user message in a Chat buffer.
---@param chat table
---@return string
local function get_chat_preview(chat)
	if type(chat.title) == "string" and chat.title ~= "" then
		return chat.title
	end
	if type(chat.messages) == "table" then
		for i = #chat.messages, 1, -1 do
			local m = chat.messages[i]
			if m and m.role == "user" and type(m.content) == "string" and m.content ~= "" then
				local first_line = m.content:gsub("%s+", " "):gsub("^%s+", "")
				return #first_line > 40 and (first_line:sub(1, 37) .. "...") or first_line
			end
		end
	end
	return "Empty chat"
end

local function pick_open_chat()
	local chat_mod = require("codecompanion.interactions.chat")
	local all = chat_mod.buf_get_chat()
	local chats = {}
	if type(all) == "table" then
		for _, entry in ipairs(all) do
			if entry.chat and vim.api.nvim_buf_is_valid(entry.chat.bufnr) then
				table.insert(chats, entry.chat)
			end
		end
	end
	if #chats == 0 then
		vim.notify("No open CodeCompanion chats", vim.log.levels.INFO, { title = "CodeCompanion" })
		return
	end
	table.sort(chats, function(a, b)
		return a.bufnr < b.bufnr
	end)

	local function format_chat_lines()
		local reqs = _G._user_cc_requests or {}
		local now = vim.uv.hrtime()
		local result = {}
		local max_w = 42
		for idx, c in ipairs(chats) do
			local winid = vim.fn.bufwinid(c.bufnr)
			local visible = winid ~= -1
			local adapter_name = (c.adapter and (c.adapter.name or c.adapter.formatted_name)) or "AI"
			local req = reqs[c.bufnr]
			local status_str = "Idle"
			if req and req.started_at then
				local elapsed = math.floor((now - req.started_at) / 1e9)
				local verb = req.phase == "streaming" and "Streaming" or "Thinking"
				status_str = string.format("%s %ds", verb, elapsed)
			end
			local preview = get_chat_preview(c)
			local line = string.format(
				" %s [%d] #%d (%s · %s) — %s ",
				visible and "●" or "○",
				idx,
				c.bufnr,
				adapter_name,
				status_str,
				preview
			)
			table.insert(result, line)
			max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
		end
		return result, max_w
	end

	local visible_win = nil
	for _, c in ipairs(chats) do
		local winid = vim.fn.bufwinid(c.bufnr)
		if winid ~= -1 then
			visible_win = winid
			break
		end
	end

	local lines, max_width = format_chat_lines()
	local width = math.min(max_width, math.max(42, math.floor(vim.o.columns * 0.5)))
	local height = math.min(#lines, 12)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local win_opts = {
		style = "minimal",
		border = "rounded",
		title = " Chats (Enter/1-9: switch · q: close) ",
		title_pos = "center",
		width = width,
		height = height,
		zindex = 60,
	}
	if visible_win and vim.api.nvim_win_is_valid(visible_win) then
		local w = vim.api.nvim_win_get_width(visible_win)
		win_opts.relative = "win"
		win_opts.win = visible_win
		win_opts.anchor = "NE"
		win_opts.row = 0
		win_opts.col = math.max(1, w - 1)
	else
		win_opts.relative = "editor"
		win_opts.anchor = "NE"
		win_opts.row = 1
		win_opts.col = math.max(1, vim.o.columns - 2)
	end

	local float_win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[float_win].cursorline = true
	vim.wo[float_win].wrap = false

	local refresh_timer = vim.uv.new_timer()
	local function stop_refresh_timer()
		if refresh_timer then
			refresh_timer:stop()
			if not refresh_timer:is_closing() then
				refresh_timer:close()
			end
			refresh_timer = nil
		end
	end

	local function close_dropdown()
		stop_refresh_timer()
		if vim.api.nvim_win_is_valid(float_win) then
			vim.api.nvim_win_close(float_win, true)
		end
	end

	if refresh_timer then
		refresh_timer:start(
			250,
			250,
			vim.schedule_wrap(function()
				if not vim.api.nvim_win_is_valid(float_win) or not vim.api.nvim_buf_is_valid(buf) then
					stop_refresh_timer()
					return
				end
				local cursor = vim.api.nvim_win_get_cursor(float_win)
				local updated = format_chat_lines()
				vim.bo[buf].modifiable = true
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, updated)
				vim.bo[buf].modifiable = false
				pcall(vim.api.nvim_win_set_cursor, float_win, cursor)
			end)
		)
	end

	local function select_index(idx)
		local target = chats[idx]
		close_dropdown()
		if not target then
			return
		end
		for _, c in ipairs(chats) do
			if c.bufnr ~= target.bufnr and c.ui and c.ui:is_visible() then
				c.ui:hide()
			end
		end
		if target.ui and target.ui.open then
			target.ui:open()
		end
	end

	local map_opts = { buffer = buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", close_dropdown, map_opts)
	vim.keymap.set("n", "<Esc>", close_dropdown, map_opts)
	vim.keymap.set("n", "<CR>", function()
		local row = vim.api.nvim_win_get_cursor(float_win)[1]
		select_index(row)
	end, map_opts)
	local function handle_mouse_click()
		local pos = vim.fn.getmousepos()
		if pos.winid == float_win and pos.line >= 1 and pos.line <= #chats then
			select_index(pos.line)
		else
			close_dropdown()
		end
	end
	vim.keymap.set("n", "<LeftMouse>", handle_mouse_click, map_opts)
	vim.keymap.set("n", "<2-LeftMouse>", handle_mouse_click, map_opts)
	for i = 1, math.min(9, #chats) do
		vim.keymap.set("n", tostring(i), function()
			select_index(i)
		end, map_opts)
	end
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		once = true,
		callback = close_dropdown,
	})
end

local function select_chat_adapter_or_model()
	local cc = require("codecompanion")
	local chat = cc.last_chat()
	if not chat then
		chat = cc.chat()
	elseif not chat.ui:is_visible() then
		chat.ui:open()
	end
	if chat then
		require("codecompanion.interactions.chat.keymaps.change_adapter").callback(chat)
	end
end

return {
	-- Plugin: vim-fugitive
	["n|<leader>G"] = map_cu("Git"):with_noremap():with_silent():with_desc("git: Open git-fugitive"),
	["n|<leader>gG"] = "",

	-- Plugin: nvim-tree
	["n|<F2>"] = map_cr("NvimTreeToggle"):with_noremap():with_silent():with_desc("filetree: Toggle"),
	["n|<C-n>"] = "",

	-- Plugin: toggleterm
	["t|jk"] = map_cmd([[<C-\><C-n>]]):with_noremap():with_silent():with_desc("terminal: Switch to normal mode"),
	["n|<leader>g"] = map_callback(function()
			helpers.toggle_lazygit()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("git: Toggle lazygit"),
	["n|<leader>gg"] = "",

	-- Plugin: trouble.nvim (v3)
	["n|gt"] = map_cr("Trouble diagnostics toggle"):with_noremap():with_silent():with_desc("lsp: Toggle trouble list"),
	["n|<leader>tr"] = map_cr("Trouble lsp_references toggle")
		:with_noremap()
		:with_silent()
		:with_desc("lsp: Show lsp references"),
	["n|<leader>td"] = map_cr("Trouble diagnostics toggle filter.buf=0")
		:with_noremap()
		:with_silent()
		:with_desc("lsp: Show document diagnostics"),
	["n|<leader>tw"] = map_cr("Trouble diagnostics toggle")
		:with_noremap()
		:with_silent()
		:with_desc("lsp: Show workspace diagnostics"),
	["n|<leader>tq"] = map_cr("Trouble qflist toggle")
		:with_noremap()
		:with_silent()
		:with_desc("lsp: Show quickfix list"),
	["n|<leader>tl"] = map_cr("Trouble loclist toggle"):with_noremap():with_silent():with_desc("lsp: Show loclist"),
	["n|<leader>lw"] = "",
	["n|<leader>lp"] = "",
	["n|<leader>ld"] = "",

	-- Plugin: telescope.nvim
	["n|<C-p>"] = "",
	["n|<A-p>"] = map_callback(function()
			require("telescope.builtin").keymaps({
				lhs_filter = function(lhs)
					return not string.find(lhs, "Þ")
				end,
				layout_config = {
					width = 0.6,
					height = 0.6,
					prompt_position = "top",
				},
			})
		end)
		:with_noremap()
		:with_silent()
		:with_desc("tool: Toggle command panel"),
	["n|<leader>u"] = map_callback(function()
			require("telescope").extensions.undo.undo()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("edit: Show undo history"),
	["n|<leader>fp"] = map_callback(function()
			require("telescope").extensions.projects.projects({})
		end)
		:with_noremap()
		:with_silent()
		:with_desc("find: Project"),
	["n|<leader>fr"] = map_callback(function()
			require("telescope").extensions.frecency.frecency({})
		end)
		:with_noremap()
		:with_silent()
		:with_desc("find: File by frecency"),
	["n|<leader>fw"] = map_callback(function()
			require("telescope").extensions.live_grep_args.live_grep_args()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("find: Word in project"),
	["n|<leader>fe"] = map_cu("Telescope oldfiles"):with_noremap():with_silent():with_desc("find: File by history"),
	["n|<leader>ff"] = map_cu("Telescope find_files"):with_noremap():with_silent():with_desc("find: File in project"),
	["n|<leader>fc"] = map_cu("Telescope colorscheme")
		:with_noremap()
		:with_silent()
		:with_desc("ui: Change colorscheme for current session"),
	["n|<leader>fn"] = map_cu("enew"):with_noremap():with_silent():with_desc("buffer: New"),
	["n|<leader>fg"] = map_cu("Telescope git_files")
		:with_noremap()
		:with_silent()
		:with_desc("find: File in git project"),
	["n|<leader>fz"] = map_cu("Telescope zoxide list")
		:with_noremap()
		:with_silent()
		:with_desc("edit: Change current directory by zoxide"),
	["n|<leader>fb"] = map_cu("Telescope buffers"):with_noremap():with_silent():with_desc("find: Buffer opened"),
	["n|<leader>fs"] = map_cu("Telescope grep_string"):with_noremap():with_silent():with_desc("find: Current word"),
	["n|<leader>fd"] = map_cu("Telescope persisted"):with_noremap():with_silent():with_desc("find: Session"),
	["n|<leader>fm"] = "",

	-- Plugin: codecompanion.nvim (oh-my-pi / pi)
	["n|<leader>cn"] = map_cr("CodeCompanionChat")
		:with_noremap()
		:with_silent()
		:with_desc("ai: New oh-my-pi Chat"),
	["n|<leader>cl"] = map_callback(pick_open_chat)
		:with_noremap()
		:with_silent()
		:with_desc("ai: List & switch open Chats"),
	["n|<leader>ct"] = map_cr("CodeCompanionChat Toggle")
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle oh-my-pi Chat"),
	["v|<leader>ct"] = map_cr("CodeCompanionChat Add")
		:with_noremap()
		:with_silent()
		:with_desc("ai: Add selection to Chat"),
	["n|<leader>ca"] = map_cr("CodeCompanionChat Toggle")
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle oh-my-pi Chat"),
	["nv|<leader>ce"] = map_cr("CodeCompanion"):with_noremap():with_silent():with_desc("ai: Inline edit (oh-my-pi)"),
	["n|<leader>cp"] = map_callback(function()
			toggle_cli_agent("omp")
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle oh-my-pi TUI"),
	["v|<leader>cp"] = map_cr("CodeCompanionCLI agent=omp")
		:with_noremap()
		:with_silent()
		:with_desc("ai: Send selection to oh-my-pi TUI"),
	["n|<leader>cP"] = map_callback(function()
			toggle_cli_agent("pi")
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle pi TUI"),
	["v|<leader>cP"] = map_cr("CodeCompanionCLI agent=pi")
		:with_noremap()
		:with_silent()
		:with_desc("ai: Send selection to pi TUI"),
	["n|<leader>ch"] = map_cr("CodeCompanionHistory"):with_noremap():with_silent():with_desc("ai: Browse Chat history"),
	["n|<leader>cs"] = map_callback(select_chat_adapter_or_model)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Select adapter / model"),
}
