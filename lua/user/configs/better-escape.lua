return function()
	local ok, better_escape = pcall(require, "better_escape")
	if not ok then
		return
	end

	-- Compatible with better-escape.nvim v2+ schema
	better_escape.setup({
		timeout = vim.o.timeoutlen,
		default_mappings = false,
		mappings = {
			i = {
				j = {
					k = "<Esc>",
					j = "<Esc>",
				},
			},
		},
	})
end
