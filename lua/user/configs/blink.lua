local icons = {
	kind = require("modules.utils.icons").get("kind"),
	type = require("modules.utils.icons").get("type"),
	cmp = require("modules.utils.icons").get("cmp"),
}
local lspkind_icons = vim.tbl_deep_extend("force", icons.kind, icons.type, icons.cmp)

local PANE_CACHE_TTL_MS = 3000
local MAX_BUFFER_LINES = 15000
local MAX_BUFFER_BYTES = 512 * 1024

---Patch cmp_tmux.tmux.get_completion_items to cache panes for 3s via async vim.system
---and use literal substring matching instead of unescaped Lua patterns.
local function patch_cmp_tmux()
	local ok, Tmux = pcall(require, "cmp_tmux.tmux")
	if not ok or type(Tmux) ~= "table" or Tmux._user_async_patched then
		return
	end
	Tmux._user_async_patched = true

	function Tmux.get_completion_items(self, current_pane, input, callback)
		local all_panes = not not (self.config and self.config.all_panes)
		local cache = self._pane_cache
		if not cache or cache.all_panes ~= all_panes then
			cache = {
				all_panes = all_panes,
				raw_panes = nil,
				timestamp = nil,
				refreshing = false,
				waiters = {},
			}
			self._pane_cache = cache
		end

		local function run_with_raw_panes(raw_panes)
			local panes = {}
			for _, p in ipairs(raw_panes) do
				if current_pane ~= p then
					table.insert(panes, p)
				end
			end

			local remainder = #panes
			if remainder == 0 then
				return callback(nil)
			end

			local input_lower = (input or ""):lower()
			local result = {}

			local function on_pane_done()
				remainder = remainder - 1
				if remainder == 0 then
					callback(vim.tbl_keys(result))
				end
			end

			for _, p in ipairs(panes) do
				local job_id = self:create_pane_data_job(p, function(data)
					if data ~= nil then
						-- Match not only full words, but URLs, paths, etc.
						for word in string.gmatch(data, "[%w%d_:/.%-~]+") do
							local word_lower = word:lower()
							if string.find(word_lower, input_lower, 1, true) then
								local clean_word = word:gsub("[:.]+$", "")
								if #clean_word > 0 then
									result[clean_word] = true
									-- Also isolate sub-words from the result
									for sub_word in string.gmatch(word, "[%w%d]+") do
										result[sub_word] = true
									end
								end
							end
						end
					end
				end, on_pane_done)

				if job_id == 0 or job_id == -1 then
					on_pane_done()
				end
			end
		end

		local now = vim.uv.now()
		if cache.raw_panes ~= nil and cache.timestamp ~= nil and (now - cache.timestamp) < PANE_CACHE_TTL_MS then
			return run_with_raw_panes(cache.raw_panes)
		end

		table.insert(cache.waiters, run_with_raw_panes)
		if cache.refreshing then
			return
		end
		cache.refreshing = true

		local cmd = { "tmux", "list-panes", "-F", "#{pane_id}" }
		if all_panes then
			table.insert(cmd, "-a")
		end

		local function finish_refresh(raw_panes)
			cache.raw_panes = raw_panes
			cache.timestamp = vim.uv.now()
			cache.refreshing = false
			local waiters = cache.waiters
			cache.waiters = {}
			for _, waiter in ipairs(waiters) do
				waiter(raw_panes)
			end
		end

		local spawned = pcall(
			vim.system,
			cmd,
			{ text = true },
			vim.schedule_wrap(function(res)
				local raw_panes = {}
				if res and res.code == 0 and type(res.stdout) == "string" then
					for p in string.gmatch(res.stdout, "%%%d+") do
						table.insert(raw_panes, p)
					end
				end
				finish_refresh(raw_panes)
			end)
		)
		if not spawned then
			finish_refresh({})
		end
	end
end

return function(opts)
	opts = opts or {}

	opts.completion = opts.completion or {}
	opts.completion.list = opts.completion.list or {}
	opts.completion.list.selection = {
		preselect = true,
		auto_insert = false,
	}

	opts.completion.menu = opts.completion.menu or {}
	opts.completion.menu.draw = opts.completion.menu.draw or {}
	opts.completion.menu.draw.components = opts.completion.menu.draw.components or {}
	opts.completion.menu.draw.components.kind_icon = opts.completion.menu.draw.components.kind_icon or {}
	opts.completion.menu.draw.components.kind_icon.text = function(ctx)
		return icons.cmp[ctx.source_id] or lspkind_icons[ctx.kind] or icons.cmp.undefined
	end

	opts.cmdline = opts.cmdline or {}
	opts.cmdline.keymap = {
		preset = "cmdline",
		["<Left>"] = false,
		["<Right>"] = false,
		["<C-e>"] = false,
	}
	opts.cmdline.completion = opts.cmdline.completion or {}
	opts.cmdline.completion.list = opts.cmdline.completion.list or {}
	opts.cmdline.completion.list.selection = {
		preselect = false,
		auto_insert = true,
	}

	opts.sources = opts.sources or {}
	opts.sources.providers = opts.sources.providers or {}

	opts.sources.providers.ripgrep = opts.sources.providers.ripgrep or {}
	opts.sources.providers.ripgrep.async = true
	opts.sources.providers.ripgrep.opts = opts.sources.providers.ripgrep.opts or {}
	opts.sources.providers.ripgrep.opts.backend = opts.sources.providers.ripgrep.opts.backend or {}
	opts.sources.providers.ripgrep.opts.backend.use = "ripgrep"
	opts.sources.providers.ripgrep.opts.backend.context_size = 3
	if opts.sources.providers.ripgrep.opts.backend.ripgrep then
		opts.sources.providers.ripgrep.opts.backend.ripgrep.context_size = nil
	end

	opts.sources.providers.tmux = opts.sources.providers.tmux or {}
	opts.sources.providers.tmux.async = true

	opts.sources.providers.buffer = opts.sources.providers.buffer or {}
	opts.sources.providers.buffer.opts = opts.sources.providers.buffer.opts or {}
	opts.sources.providers.buffer.opts.get_bufnrs = function()
		if vim.api.nvim_buf_line_count(0) >= MAX_BUFFER_LINES then
			return {}
		end
		local bufnrs = {}
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
				local line_count = vim.api.nvim_buf_line_count(buf)
				local ok_bytes, bytes = pcall(vim.api.nvim_buf_get_offset, buf, line_count)
				if ok_bytes and bytes >= 0 and bytes <= MAX_BUFFER_BYTES then
					table.insert(bufnrs, buf)
				end
			end
		end
		return bufnrs
	end

	patch_cmp_tmux()

	return opts
end
