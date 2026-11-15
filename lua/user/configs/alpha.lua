return function()
	local dashboard = require("alpha.themes.dashboard")
	local leader = "space"

	local function button(sc, txt, leader_txt, keybind, keybind_opts)
		local sc_after = sc:gsub("%s", ""):gsub(leader_txt, "<leader>")

		local opts = {
			position = "center",
			shortcut = sc,
			cursor = 5,
			width = 50,
			align_shortcut = "right",
			hl = "AlphaButtons",
			hl_shortcut = "AlphaShortcut",
		}

		if keybind then
			keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
			opts.keymap = { "n", sc_after, keybind, keybind_opts }
		end

		local function on_press()
			local key = vim.api.nvim_replace_termcodes((keybind or sc_after) .. "<Ignore>", true, false, true)
			vim.api.nvim_feedkeys(key, "t", false)
		end

		return {
			type = "button",
			val = txt,
			on_press = on_press,
			opts = opts,
		}
	end

	dashboard.section.buttons.val = {
		-- button("space f c", " Scheme change", leader),
		button("space f r", " File frecency", leader),
		button("space f e", "󰋚 File history", leader),
		button("space f p", " Project find", leader),
		button("space f f", "󰈞 File find", leader),
		button("space f n", " File new", leader),
		button("space f w", " Word find", leader),
	}
	dashboard.section.buttons.opts.hl = "AlphaButtons"

	local function custom_footer()
		local stats = require("lazy").stats()
		local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
		return "   FREEDOM IS NOT FREE "
			.. "  󰀨 v"
			.. vim.version().major
			.. "."
			.. vim.version().minor
			.. "."
			.. vim.version().patch
			.. "  󰂖 "
			.. stats.count
			.. " plugins in "
			.. ms
			.. "ms"
	end

	dashboard.section.footer.val = custom_footer()

	local head_butt_padding = 2
	local occu_height = #dashboard.section.header.val + 2 * #dashboard.section.buttons.val + head_butt_padding
	local header_padding = math.max(0, math.ceil((vim.fn.winheight(0) - occu_height) * 0.25))
	if dashboard.config and dashboard.config.layout and dashboard.config.layout[1] then
		dashboard.config.layout[1].val = header_padding
	end

	vim.api.nvim_create_autocmd("User", {
		group = vim.api.nvim_create_augroup("UserAlphaFooter", { clear = true }),
		pattern = "LazyVimStarted",
		callback = function()
			for _, ac in ipairs(vim.api.nvim_get_autocmds({ event = "User", pattern = "LazyVimStarted" })) do
				if not ac.group_name and ac.callback then
					local src = debug.getinfo(ac.callback, "S").source or ""
					if src:find("modules/configs/ui/alpha.lua", 1, true) then
						pcall(vim.api.nvim_del_autocmd, ac.id)
					end
				end
			end
			vim.schedule(function()
				dashboard.section.footer.val = custom_footer()
				pcall(vim.cmd.AlphaRedraw)
			end)
		end,
	})

	return dashboard.opts
end
