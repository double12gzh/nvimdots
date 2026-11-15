if vim.fn.exists(":MasonInstallAll") ~= 2 then
	vim.api.nvim_create_user_command("MasonInstallAll", function()
		local settings = require("core.settings")
		local registry = require("mason-registry")
		pcall(registry.refresh)

		local lsp_to_pkg = {}
		for _, spec in ipairs(registry.get_all_package_specs()) do
			local lspconfig = vim.tbl_get(spec, "neovim", "lspconfig")
			if lspconfig then
				lsp_to_pkg[lspconfig] = spec.name
			end
		end

		local ok_null, null_map = pcall(require, "mason-null-ls.mappings.source")
		local ok_dap, dap_map = pcall(require, "mason-nvim-dap.mappings.source")

		local candidates = {}
		for _, lsp_name in ipairs(settings.lsp_deps or {}) do
			if lsp_name ~= "rust_analyzer" then
				table.insert(candidates, lsp_to_pkg[lsp_name] or lsp_name)
			end
		end
		for _, null_name in ipairs(settings.null_ls_deps or {}) do
			local mapped = ok_null and null_map.getPackageFromNullLs and null_map.getPackageFromNullLs(null_name)
			table.insert(candidates, mapped or null_name:gsub("_", "-"))
		end
		for _, dap_name in ipairs(settings.dap_deps or {}) do
			local mapped = ok_dap and dap_map.nvim_dap_to_package and dap_map.nvim_dap_to_package[dap_name]
			table.insert(candidates, mapped or dap_name)
		end

		local seen = {}
		local missing = {}
		for _, pkg in ipairs(candidates) do
			if pkg and not seen[pkg] then
				seen[pkg] = true
				if registry.has_package(pkg) and not registry.is_installed(pkg) then
					table.insert(missing, pkg)
				end
			end
		end

		if #missing > 0 then
			local prefix = #vim.api.nvim_list_uis() == 0 and "MasonInstall --quiet " or "MasonInstall "
			vim.cmd(prefix .. table.concat(missing, " "))
		end
	end, { desc = "Install all configured Mason packages" })
end

return {
	max_concurrent_installers = 30,
}
