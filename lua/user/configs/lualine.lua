return function(opts)
	local icons = {
		aichat = require("modules.utils.icons").get("aichat", true),
		ui = require("modules.utils.icons").get("ui", true),
	}

	opts.options.theme = "auto"

	---Check whether the current buffer belongs to a Git repo or worktree,
	---using gitsigns buffer vars first and falling back to a per-buffer cache.
	---@return boolean
	local function has_git()
		if vim.b.gitsigns_head ~= nil or vim.b.gitsigns_status_dict ~= nil then
			return true
		end
		local bufname = vim.api.nvim_buf_get_name(0)
		local cwd = vim.uv.cwd()
		local cached = vim.b._user_has_git
		if type(cached) == "table" and cached.bufname == bufname and cached.cwd == cwd then
			return cached.has_git
		end
		local path = bufname ~= "" and vim.fs.dirname(bufname) or cwd
		local found = path ~= nil and path ~= "" and #vim.fs.find(".git", { limit = 1, upward = true, path = path }) > 0
		vim.b._user_has_git = {
			bufname = bufname,
			cwd = cwd,
			has_git = found,
		}
		return found
	end

	-- Use empty separator instead of vertical bar "│" and cache git checks
	if opts.sections and opts.sections.lualine_b and opts.sections.lualine_b[3] then
		opts.sections.lualine_b[3][1] = function()
			return ""
		end
		opts.sections.lualine_b[3].cond = function()
			return has_git() and vim.bo.filetype ~= ""
		end
	end
	if opts.sections and opts.sections.lualine_c then
		if opts.sections.lualine_c[1] then
			opts.sections.lualine_c[1].cond = has_git
		end
		if opts.sections.lualine_c[2] then
			opts.sections.lualine_c[2].cond = has_git
		end
	end
	if opts.sections and opts.sections.lualine_y and opts.sections.lualine_y[1] then
		opts.sections.lualine_y[1][1] = function()
			return ""
		end
	end

	---Resolve a hex foreground color from a highlight group with a fallback.
	---@param hl_name string
	---@param fallback string
	---@return string
	local function resolve_hl_fg(hl_name, fallback)
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
		if ok and type(hl) == "table" and hl.fg then
			return string.format("#%06x", hl.fg)
		end
		return fallback
	end

	-- Enhance CodeCompanion statusline indicator with clear identifier, phase, elapsed time, and high-contrast color
	if opts.sections and opts.sections.lualine_x and opts.sections.lualine_x[1] then
		_G._user_cc_requests = _G._user_cc_requests or {}
		local requests_by_key = _G._user_cc_requests
		local animation_idx = 1
		local animate_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
		local spinner_timer = nil

		---Count active CodeCompanion requests.
		---@return number
		local function active_request_count()
			local n = 0
			for _ in pairs(requests_by_key) do
				n = n + 1
			end
			return n
		end

		---Format a token count compactly (e.g. 850 -> "850 tok", 8710 -> "8.7k tok").
		---@param count number
		---@return string
		local function format_tokens(count)
			if count >= 1000 then
				return string.format("%.1fk tok", count / 1000)
			end
			return string.format("%d tok", count)
		end

		---Shorten a hierarchical model ID (e.g. "magpie/group/gpt-6-astra" -> "gpt-6-astra").
		---@param model string
		---@return string
		local function short_model_name(model)
			local tail = model:match("([^/]+)$")
			return tail or model
		end

		---Find the active/visible CodeCompanion chat instance without forcing lazy-load.
		---@return table|nil
		local function get_visible_chat()
			local chat_mod = package.loaded["codecompanion.interactions.chat"]
			if not chat_mod then
				return nil
			end
			local cur = chat_mod.buf_get_chat(0)
			if cur then
				return cur
			end
			local all = chat_mod.buf_get_chat()
			if type(all) == "table" then
				for _, entry in ipairs(all) do
					local c = entry.chat
					if c and c.ui and c.ui:is_visible() then
						return c
					end
				end
			end
			local last = chat_mod.last_chat()
			if last and last.ui and last.ui:is_visible() then
				return last
			end
			return nil
		end

		---Extract adapter, model, mode, and token count from a CodeCompanion chat.
		---@param chat table
		---@return { adapter: string, model?: string, mode?: string, tokens?: string }
		local function get_chat_metadata(chat)
			local meta = {
				adapter = (chat.adapter and (chat.adapter.name or chat.adapter.formatted_name)) or "AI",
			}

			if chat.adapter and chat.adapter.type == "acp" and chat.acp_connection and chat.acp_connection.get_config_options then
				for _, opt in ipairs(chat.acp_connection:get_config_options()) do
					if opt.category == "model" and type(opt.currentValue) == "string" and opt.currentValue ~= "" then
						meta.model = short_model_name(opt.currentValue)
					elseif
						opt.category == "mode"
						and type(opt.currentValue) == "string"
						and opt.currentValue ~= ""
						and opt.currentValue ~= "default"
					then
						meta.mode = opt.currentValue
					end
				end
			elseif chat.adapter and chat.adapter.schema and chat.adapter.schema.model then
				local m = chat.adapter.schema.model.default
				if type(m) == "string" and m ~= "" then
					meta.model = short_model_name(m)
				end
			end

			if type(chat.tokens) == "number" and chat.tokens > 0 then
				meta.tokens = format_tokens(chat.tokens)
			end
			return meta
		end

		_G._user_cc_winbar_click = function(target_bufnr)
			local chat_mod = package.loaded["codecompanion.interactions.chat"]
			if not chat_mod or type(target_bufnr) ~= "number" or target_bufnr <= 0 then
				return
			end
			local target = chat_mod.buf_get_chat(target_bufnr)
			if not target then
				return
			end
			local all_entries = chat_mod.buf_get_chat()
			if type(all_entries) == "table" then
				for _, entry in ipairs(all_entries) do
					local c = entry.chat
					if c and c.bufnr ~= target_bufnr and c.ui and c.ui:is_visible() then
						c.ui:hide()
					end
				end
			end
			if target.ui and target.ui.open then
				target.ui:open()
			end
		end

		---Update winbar on all visible CodeCompanion chat windows so each split shows all open chats and their live state.
		local function update_chat_winbars()
			local chat_mod = package.loaded["codecompanion.interactions.chat"]
			if not chat_mod then
				return
			end
			local all_entries = chat_mod.buf_get_chat()
			local chats = {}
			if type(all_entries) == "table" then
				for _, entry in ipairs(all_entries) do
					if entry.chat and vim.api.nvim_buf_is_valid(entry.chat.bufnr) then
						table.insert(chats, entry.chat)
					end
				end
			end
			table.sort(chats, function(a, b)
				return a.bufnr < b.bufnr
			end)

			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == "codecompanion" then
					local cur_chat = chat_mod.buf_get_chat(buf)
					if cur_chat then
						local tabs = {}
						for idx, c in ipairs(chats) do
							local req = requests_by_key[c.bufnr]
							local is_cur = (c.bufnr == buf)
							local state_str, hl
							if req then
								local elapsed = math.floor((vim.uv.hrtime() - req.started_at) / 1e9)
								local verb = req.phase == "streaming" and "S" or "T"
								state_str = string.format("%s %s%ds", animate_chars[animation_idx], verb, elapsed)
								hl = req.phase == "streaming" and "DiagnosticOk" or "DiagnosticWarn"
							else
								state_str = "Idle"
								hl = is_cur and "DiagnosticInfo" or "Comment"
							end
							local marker = is_cur and "●" or "○"
							table.insert(
								tabs,
								string.format(
									"%%#%s#%%%d@v:lua._user_cc_winbar_click@%s %d:%s%%X%%*",
									hl,
									c.bufnr,
									marker,
									idx,
									state_str
								)
							)
						end

						vim.wo[win].winbar = string.format(" %s%s", icons.aichat.Chat, table.concat(tabs, " "))
					end
				end
			end
		end

		local function stop_spinner_timer()
			if spinner_timer then
				spinner_timer:stop()
				if not spinner_timer:is_closing() then
					spinner_timer:close()
				end
				spinner_timer = nil
			end
		end

		local function start_spinner_timer()
			if spinner_timer then
				return
			end
			spinner_timer = vim.uv.new_timer()
			if not spinner_timer then
				return
			end
			spinner_timer:start(
				120,
				120,
				vim.schedule_wrap(function()
					if active_request_count() <= 0 then
						stop_spinner_timer()
						return
					end
					animation_idx = animation_idx % #animate_chars + 1
					update_chat_winbars()
					pcall(vim.cmd.redrawstatus)
				end)
			)
		end

		local cc_group = vim.api.nvim_create_augroup("CodeCompanionHooks", { clear = true })
		vim.api.nvim_create_autocmd("User", {
			pattern = {
				"CodeCompanionRequestStarted",
				"CodeCompanionRequestStreaming",
				"CodeCompanionRequestFinished",
			},
			group = cc_group,
			callback = function(args)
				local data = args.data or {}
				local bufnr = data.bufnr
				local key = bufnr or "global"
				local adapter = data.adapter
				local adapter_name = (type(adapter) == "table" and (adapter.name or adapter.formatted_name)) or "AI"

				if args.match == "CodeCompanionRequestStarted" then
					requests_by_key[key] = {
						bufnr = bufnr,
						interaction = data.interaction,
						adapter = adapter_name,
						phase = "thinking",
						started_at = vim.uv.hrtime(),
					}
					start_spinner_timer()
				elseif args.match == "CodeCompanionRequestStreaming" then
					local req = requests_by_key[key]
					if req then
						req.phase = "streaming"
					else
						requests_by_key[key] = {
							bufnr = bufnr,
							interaction = data.interaction,
							adapter = adapter_name,
							phase = "streaming",
							started_at = vim.uv.hrtime(),
						}
					end
					start_spinner_timer()
				elseif args.match == "CodeCompanionRequestFinished" then
					requests_by_key[key] = nil
					if active_request_count() == 0 then
						stop_spinner_timer()
					end
				end

				vim.schedule(function()
					update_chat_winbars()
					pcall(vim.cmd.redrawstatus)
				end)
			end,
		})

		vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
			group = cc_group,
			callback = function(args)
				if vim.bo[args.buf].filetype == "codecompanion" then
					vim.schedule(update_chat_winbars)
				end
			end,
		})

		---Build idle status text for a visible CodeCompanion Chat or CLI instance.
		---@return string
		local function get_idle_status()
			local chat = get_visible_chat()
			if chat and chat.adapter then
				local meta = get_chat_metadata(chat)
				local parts = { icons.aichat.Chat .. meta.adapter }
				if meta.model then
					table.insert(parts, meta.model)
				end
				if meta.mode then
					table.insert(parts, meta.mode)
				end
				if meta.tokens then
					table.insert(parts, meta.tokens)
				end
				return table.concat(parts, " · ")
			end

			local cli_mod = package.loaded["codecompanion.interactions.cli"]
			if cli_mod and cli_mod.get_visible then
				local cli = cli_mod.get_visible()
				if cli then
					return string.format("%s%s (CLI)", icons.aichat.Chat, cli.agent_name or "cli")
				end
			end

			return ""
		end

		---Get sorted active request entries.
		---@return table[]
		local function get_sorted_requests()
			local list = {}
			for _, req in pairs(requests_by_key) do
				table.insert(list, req)
			end
			table.sort(list, function(a, b)
				return (a.bufnr or 0) < (b.bufnr or 0)
			end)
			return list
		end

		opts.sections.lualine_x[1] = {
			function()
				local reqs = get_sorted_requests()
				if #reqs == 0 then
					return get_idle_status()
				end

				local cur_buf = vim.api.nvim_get_current_buf()
				local now = vim.uv.hrtime()
				local chat_mod = package.loaded["codecompanion.interactions.chat"]

				if #reqs == 1 then
					local req = reqs[1]
					local elapsed = math.floor((now - req.started_at) / 1e9)
					local status_text = req.phase == "streaming" and "Streaming" or "Thinking"
					local chat = req.bufnr and chat_mod and chat_mod.buf_get_chat(req.bufnr) or get_visible_chat()
					local is_hidden = req.bufnr and vim.fn.bufwinid(req.bufnr) == -1
					local meta = chat and get_chat_metadata(chat) or { adapter = req.adapter }
					local parts = { icons.aichat.Chat .. meta.adapter }
					if meta.model then
						table.insert(parts, meta.model)
					end
					if meta.mode then
						table.insert(parts, meta.mode)
					end
					local bg_tag = is_hidden and " [bg]" or ""
					table.insert(parts, string.format("%s %s %ds%s", animate_chars[animation_idx], status_text, elapsed, bg_tag))
					if meta.tokens then
						table.insert(parts, meta.tokens)
					end
					return table.concat(parts, " · ")
				end

				local segs = {}
				for _, req in ipairs(reqs) do
					local elapsed = math.floor((now - req.started_at) / 1e9)
					local status_text = req.phase == "streaming" and "Streaming" or "Thinking"
					local buf_tag = req.bufnr and ("#" .. tostring(req.bufnr)) or "?"
					if req.bufnr and req.bufnr == cur_buf then
						buf_tag = buf_tag .. "*"
					elseif req.bufnr and vim.fn.bufwinid(req.bufnr) == -1 then
						buf_tag = buf_tag .. "[bg]"
					end
					table.insert(segs, string.format("%s %s %s %ds", buf_tag, animate_chars[animation_idx], status_text, elapsed))
				end
				return icons.aichat.Chat .. table.concat(segs, " | ")
			end,
			on_click = function()
				local reqs = get_sorted_requests()
				local target = reqs[1]
				if target and target.bufnr then
					local winid = vim.fn.bufwinid(target.bufnr)
					if winid ~= -1 then
						vim.api.nvim_set_current_win(winid)
						return
					end
					local chat_mod = package.loaded["codecompanion.interactions.chat"]
					local chat = chat_mod and chat_mod.buf_get_chat(target.bufnr)
					if chat and chat.ui and chat.ui.open then
						chat.ui:open()
						return
					end
				end
				if target and target.interaction == "cli" then
					vim.cmd("CodeCompanionCLI")
				else
					vim.cmd("CodeCompanionChat Toggle")
				end
			end,
			color = function()
				local reqs = get_sorted_requests()
				if #reqs == 0 then
					return { fg = resolve_hl_fg("DiagnosticInfo", "#83a598"), gui = "bold" }
				end
				local cur_buf = vim.api.nvim_get_current_buf()
				local active_req = requests_by_key[cur_buf] or reqs[1]
				if active_req and active_req.phase == "streaming" then
					return { fg = resolve_hl_fg("DiagnosticOk", "#b8bb26"), gui = "bold" }
				end
				return { fg = resolve_hl_fg("DiagnosticWarn", "#fabd2f"), gui = "bold" }
			end,
			cond = function()
				return vim.o.columns > 60
			end,
		}
	end

	-- Display buffer shiftwidth instead of tabstop
	if opts.sections and opts.sections.lualine_x and opts.sections.lualine_x[4] then
		opts.sections.lualine_x[4][1] = function()
			return icons.ui.Tab .. vim.bo.shiftwidth
		end
	end

	-- Restore compact sidebar/panel statuslines (upstream emptied `extensions` for disabled `edgy.nvim`)
	local mini_sections = {
		lualine_a = { "filetype" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	}
	opts.extensions = {
		"quickfix",
		"nvim-tree",
		"nvim-dap-ui",
		"toggleterm",
		"fugitive",
		"trouble",
		{
			sections = mini_sections,
			filetypes = { "Outline", "lspsagaoutline" },
		},
		{
			sections = mini_sections,
			filetypes = { "DiffviewFiles" },
		},
	}

	return opts
end
