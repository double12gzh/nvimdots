return function()
	local cmd = nil
	if vim.fn.executable("rustup") == 1 then
		local out = vim.fn.systemlist({ "rustup", "which", "rust-analyzer" })
		if vim.v.shell_error == 0 and out[1] and vim.fn.executable(out[1]) == 1 then
			cmd = function()
				return { out[1] }
			end
		end
	end

	vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, {
		server = {
			cmd = cmd,
			standalone = true,
			capabilities = require("modules.utils").get_lsp_capabilities(),
		},
	})
end
