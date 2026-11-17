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

	-- Plugin: codecompanion.nvim + cc-workspace.nvim (oh-my-pi / pi)
	["n|<leader>cn"] = map_callback(function()
			require("cc_workspace").new_smart_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: New oh-my-pi Chat"),
	["n|<leader>cN"] = map_callback(function()
			require("cc_workspace").prompt_new_project_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: New Chat in Project"),
	["n|<leader>cj"] = map_callback(function()
			local ws = require("cc_workspace")
			ws.enter(false, { skip_auto_chat = true })
			ws.prompt_add_project()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Add Project to AI Workspace"),
	["n|<leader>cl"] = map_callback(function()
			require("cc_workspace.switcher").open()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: List & switch open Chats"),
	["n|<leader>cu"] = map_callback(function()
			require("cc_workspace.switcher").jump_to_attention()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Jump to unread / attention Chat"),
	["n|<leader>cb"] = map_callback(function()
			require("cc_workspace.switcher").create_worktree_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: New Git Worktree & Agent Chat"),
	["n|<leader>cT"] = map_callback(function()
			require("cc_workspace.switcher").create_worktree_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: New Git Worktree & Agent Chat"),
	["n|<leader>cw"] = map_callback(function()
			require("cc_workspace").toggle()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle AI Workspace tab"),
	["n|<leader>cW"] = map_callback(function()
			require("cc_workspace").toggle()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle AI Workspace tab"),
	["v|<leader>cw"] = map_callback(function()
			require("cc_workspace").send_visual_selection()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Send selection to AI Workspace"),
	["v|<leader>cW"] = map_callback(function()
			require("cc_workspace").send_visual_selection()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Send selection to AI Workspace"),
	["n|<leader>ct"] = map_callback(function()
			require("cc_workspace").toggle_side_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Toggle oh-my-pi Chat"),
	["v|<leader>ct"] = map_callback(function()
			require("cc_workspace").add_visual_to_chat()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Add selection to Chat"),
	["n|<leader>ca"] = map_callback(function()
			require("cc_workspace").toggle_side_chat()
		end)
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
	["n|<leader>ch"] = map_callback(function()
			require("codecompanion")
			require("cc_workspace").patch_history_ui()
			pcall(vim.cmd, "CodeCompanionHistory")
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Browse Chat history"),
	["n|<leader>cs"] = map_callback(function()
			require("cc_workspace.switcher").select_adapter_or_model()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Select adapter / model"),
	["n|<leader>ck"] = map_callback(function()
			require("cc_workspace").show_keys()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("ai: Inspect AI Workspace keymaps"),
}
