local function find_executable(name, fallbacks)
	local path = vim.fn.exepath(name)
	if path ~= "" then
		return path
	end

	for _, candidate in ipairs(fallbacks or {}) do
		local expanded = vim.fn.expand(candidate)
		if vim.fn.executable(expanded) == 1 then
			return expanded
		end
	end

	return nil
end

local function resolve_pi_cli(pi_path, bun_path)
	if bun_path and bun_path ~= "" then
		local f = io.open(pi_path, "r")
		if f then
			local first_line = f:read("*l")
			f:close()
			if type(first_line) == "string" and first_line:match("^#!.*node") then
				return { cmd = bun_path, args = { pi_path } }
			end
		end
	end

	return { cmd = pi_path, args = {} }
end

local function load_local_http_provider()
	local candidates = {
		vim.fn.expand("~/.omp/agent/models.json"),
		vim.fn.expand("~/.pi/agent/models.json"),
	}

	for _, path in ipairs(candidates) do
		local f = io.open(path, "r")
		if f then
			local content = f:read("*a")
			f:close()

			local ok, decoded = pcall(vim.json.decode, content)
			if ok and type(decoded) == "table" and type(decoded.providers) == "table" then
				local chosen = nil
				local magpie = decoded.providers.magpie
				if
					type(magpie) == "table"
					and magpie.api == "openai-completions"
					and type(magpie.baseUrl) == "string"
				then
					chosen = magpie
				else
					for _, provider in pairs(decoded.providers) do
						if
							type(provider) == "table"
							and provider.api == "openai-completions"
							and type(provider.baseUrl) == "string"
						then
							chosen = provider
							break
						end
					end
				end

				if chosen then
					local base_url = chosen.baseUrl:gsub("/+$", "")
					local base_root, chat_url, models_endpoint
					if base_url:sub(-3) == "/v1" then
						base_root = base_url:sub(1, -4)
						chat_url = "/v1/chat/completions"
						models_endpoint = "/v1/models"
					else
						base_root = base_url
						chat_url = "/chat/completions"
						models_endpoint = "/models"
					end

					local models = {}
					local fast_model = nil
					local default_model = nil
					if type(chosen.models) == "table" then
						for _, m in ipairs(chosen.models) do
							if type(m) == "table" and type(m.id) == "string" and m.id ~= "" then
								table.insert(models, m.id)
								if not fast_model and m.id:match("flash") then
									fast_model = m.id
								end
								if
									not default_model
									and (m.id:match("claude%-opus") or m.id:match("gpt%-6") or m.id:match("gpt%-5"))
								then
									default_model = m.id
								end
							end
						end
					end

					if #models > 0 then
						return {
							api_key = chosen.apiKey or "",
							base_root = base_root,
							chat_url = chat_url,
							models_endpoint = models_endpoint,
							models = models,
							default_model = default_model or models[1],
							fast_model = fast_model or models[1],
						}
					end
				end
			end
		end
	end

	return nil
end

local function patch_chat_context_stripper()
	local ok, chat_helpers = pcall(require, "codecompanion.interactions.chat.helpers")
	if not ok or type(chat_helpers) ~= "table" or chat_helpers._omp_context_patched then
		return
	end
	chat_helpers._omp_context_patched = true

	-- Split blockquote lines individually so lazy CommonMark continuation doesn't swallow user prompts
	chat_helpers.strip_context = function(messages)
		local i = 1
		while messages[i] and messages[i]:sub(1, 1) == ">" do
			local remaining = {}
			local stripping = true
			for _, line in ipairs(vim.split(messages[i], "\n", { plain = true })) do
				if stripping and line:sub(1, 1) == ">" then
					-- Drop leading "> ..." context blockquote lines only
				else
					stripping = false
					table.insert(remaining, line)
				end
			end
			local cleaned = vim.trim(table.concat(remaining, "\n"))
			if cleaned == "" then
				table.remove(messages, i)
			else
				messages[i] = cleaned
				break
			end
		end
		return messages
	end
end

return function(opts)
	opts = opts or {}

	local omp_bin = find_executable("omp", { "~/.local/bin/omp", "/opt/homebrew/bin/omp" })
	local pi_bin = find_executable("pi", { "~/.local/bin/pi", "/opt/homebrew/bin/pi" })
	local bun_bin = find_executable("bun", { "/opt/homebrew/bin/bun", "~/.bun/bin/bun" })
	local local_http = load_local_http_provider()

	local aichat_icons = require("modules.utils.icons").get("aichat", true)
	opts.interactions = vim.tbl_deep_extend("force", opts.interactions or {}, opts.strategies or {})
	opts.strategies = nil
	opts.interactions.chat = opts.interactions.chat or {}
	opts.interactions.chat.roles = vim.tbl_deep_extend("force", opts.interactions.chat.roles or {}, {
		llm = function(adapter)
			return aichat_icons.Chat .. "CodeCompanion (" .. adapter.formatted_name .. ")"
		end,
	})
	opts.interactions.chat.keymaps = opts.interactions.chat.keymaps or {}
	-- Remove legacy v19 duplicate `submit` keymap inherited from upstream module config
	opts.interactions.chat.keymaps.submit = nil

	opts.opts = vim.tbl_deep_extend("force", opts.opts or {}, { language = "Chinese" })

	opts.adapters = opts.adapters or {}
	opts.adapters.acp = opts.adapters.acp or {}
	opts.adapters.http = opts.adapters.http or {}

	if omp_bin then
		opts.adapters.acp.omp = function()
			local helpers = require("codecompanion.adapters.acp.helpers")
			return require("codecompanion.adapters.acp").new({
				name = "omp",
				formatted_name = "oh-my-pi",
				type = "acp",
				roles = {
					llm = "assistant",
					user = "user",
				},
				opts = {
					vision = true,
				},
				commands = {
					default = { omp_bin, "acp" },
				},
				defaults = {
					auth_method = "agent",
					mcpServers = {},
					timeout = 30000,
				},
				parameters = {
					protocolVersion = 1,
					clientCapabilities = {
						fs = { readTextFile = true, writeTextFile = true },
					},
					clientInfo = {
						name = "CodeCompanion.nvim",
						version = "20.1.0",
					},
				},
				handlers = {
					lifecycle = {
						setup = function()
							return true
						end,
					},
					request = {
						build_messages = helpers.build_messages,
					},
				},
			})
		end
	end

	if local_http then
		opts.adapters.http.omp_http = function()
			return require("codecompanion.adapters").extend("openai_compatible", {
				name = "omp_http",
				formatted_name = "oh-my-pi (HTTP)",
				env = {
					api_key = function()
						local k = local_http.api_key
						local env_v = (k ~= "" and os.getenv(k)) or nil
						return (env_v and env_v ~= "") and env_v or k
					end,
					url = local_http.base_root,
					chat_url = local_http.chat_url,
					models_endpoint = local_http.models_endpoint,
				},
				schema = {
					model = {
						default = local_http.default_model,
						choices = local_http.models,
					},
				},
			})
		end
	end

	local primary_adapter = omp_bin and "omp" or (local_http and "omp_http" or nil)
	if primary_adapter then
		opts.interactions.chat = opts.interactions.chat or {}
		opts.interactions.chat.adapter = primary_adapter
		opts.interactions.inline = opts.interactions.inline or {}
		opts.interactions.inline.adapter = primary_adapter
	end

	if local_http then
		opts.interactions.cmd = opts.interactions.cmd or {}
		opts.interactions.cmd.adapter = "omp_http"
	end

	local cli_agents = {}
	if omp_bin then
		cli_agents.omp = {
			cmd = omp_bin,
			args = {},
			description = "oh-my-pi (omp) TUI",
			provider = "terminal",
		}
	end
	if pi_bin then
		local pi_cli = resolve_pi_cli(pi_bin, bun_bin)
		cli_agents.pi = {
			cmd = pi_cli.cmd,
			args = pi_cli.args,
			description = "pi coding agent TUI",
			provider = "terminal",
		}
	end

	opts.interactions.cli = vim.tbl_deep_extend("force", opts.interactions.cli or {}, {
		agent = omp_bin and "omp" or (pi_bin and "pi" or nil),
		agents = cli_agents,
		opts = { auto_insert = true },
	})

	opts.display = opts.display or {}
	opts.display.chat = opts.display.chat or {}
	-- Avoid colliding with render-markdown.nvim H2 banner on role headings
	opts.display.chat.show_header_separator = false
	opts.display.chat.intro_message = aichat_icons.Chat
		.. "Enter/C-s 发送 · / 命令 · # 上下文 · ga 切换模型 · q 停止/收起 · ? 帮助"
	opts.display.chat.window = vim.tbl_deep_extend("force", opts.display.chat.window or {}, {
		layout = "vertical",
		position = "right",
		width = 0.32,
		pertab = true,
	})
	opts.display.cli = vim.tbl_deep_extend("force", opts.display.cli or {}, {
		window = {
			layout = "vertical",
			position = "right",
			width = 0.38,
			border = "single",
		},
	})

	opts.extensions = opts.extensions or {}
	opts.extensions.history = opts.extensions.history or {}
	opts.extensions.history.opts = opts.extensions.history.opts or {}
	if local_http then
		opts.extensions.history.opts.auto_generate_title = true
		opts.extensions.history.opts.title_generation_opts = {
			adapter = "omp_http",
			model = local_http.fast_model,
		}
		opts.extensions.history.opts.summary = {
			generation_opts = {
				adapter = "omp_http",
				model = local_http.fast_model,
			},
		}
	elseif primary_adapter == "omp" then
		opts.extensions.history.opts.auto_generate_title = false
	end

	opts.extensions.workspace = {
		enabled = true,
		callback = "codecompanion._extensions.workspace",
		opts = {},
	}

	patch_chat_context_stripper()
	vim.schedule(function()
		if not package.loaded["lualine"] then
			pcall(require, "lualine")
		end
		patch_chat_context_stripper()
	end)

	return opts
end
