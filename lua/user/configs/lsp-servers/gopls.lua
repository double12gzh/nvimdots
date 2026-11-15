return function(defaults)
	vim.lsp.config("gopls", {
		capabilities = defaults.capabilities,
		flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
		cmd = { "gopls", "-remote=auto" },
		filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
		settings = {
			gopls = {
				usePlaceholders = true,
				codelenses = {
					generate = true,
					gc_details = true,
					test = true,
					tidy = true,
					vendor = true,
					regenerate_cgo = true,
					run_vulncheck_exp = true,
					upgrade_dependency = true,
				},
				directoryFilters = {
					"-**/node_modules",
					"-/tmp",
				},
				verboseOutput = false,
				semanticTokens = true,
				completeUnimported = true,
				completionDocumentation = true,
				staticcheck = true,
				gofumpt = true,
				linksInHover = true,
				buildFlags = { "-tags=integration,e2e" },
			},
		},
	})
end
