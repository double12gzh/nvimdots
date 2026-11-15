return function()
	local cached_bin = nil
	local function resolve_cmd()
		if not cached_bin then
			cached_bin = "rust-analyzer"
			if vim.fn.executable("rustup") == 1 then
				local out = vim.fn.systemlist({ "rustup", "which", "rust-analyzer" })
				if vim.v.shell_error == 0 and out[1] and vim.fn.executable(out[1]) == 1 then
					cached_bin = out[1]
				end
			end
		end
		return { cached_bin }
	end

	vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, {
		server = {
			cmd = resolve_cmd,
			standalone = true,
			capabilities = require("modules.utils").get_lsp_capabilities(),
		},
	})
end
