vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("UserAsyncTmuxYank", { clear = true }),
	pattern = "*",
	desc = "Copy yanked text to tmux buffer asynchronously",
	callback = function()
		if vim.b.smartyank_disable or vim.g.smartyank_disable then
			return
		end
		local tmux = vim.env.TMUX
		if not tmux or tmux == "" or vim.fn.executable("tmux") ~= 1 then
			return
		end
		local event = vim.v.event
		local contents = event and event.regcontents
		if not contents or #contents == 0 then
			return
		end
		local text = table.concat(contents, "\n")
		if text == "" then
			return
		end
		vim.system({ "tmux", "load-buffer", "-w", "-" }, { stdin = text }, function() end)
	end,
})

return {
	clipboard = { enabled = false },
	tmux = { enabled = false },
}
