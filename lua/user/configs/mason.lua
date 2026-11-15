local PYLSP_PLUGINS = {
	"python-lsp-black",
	"python-lsp-ruff",
	"pylsp-rope",
}

local pylsp_state = {
	hook_registered = false,
	pending = false,
	job = nil,
	rerun = false,
	rerun_pkg = nil,
	last_ok = nil,
	last_err = nil,
}

local function get_pylsp_venv_paths(pkg)
	local is_windows = require("core.global").is_windows
	local pkg_path = (pkg and pkg.get_install_path and pkg:get_install_path())
		or (vim.fn.stdpath("data") .. "/mason/packages/python-lsp-server")
	local venv = pkg_path .. "/venv"

	if is_windows then
		local scripts_dir = venv .. "/Scripts"
		local bin_dir = vim.fn.executable(scripts_dir .. "/python.exe") == 1 and scripts_dir or (venv .. "/bin")
		return {
			venv = venv,
			python = bin_dir .. "/python.exe",
			black = bin_dir .. "/black.exe",
			ruff = bin_dir .. "/ruff.exe",
		}
	end

	return {
		venv = venv,
		python = venv .. "/bin/python",
		black = venv .. "/bin/black",
		ruff = venv .. "/bin/ruff",
	}
end

local function are_pylsp_plugins_installed(pkg)
	local paths = get_pylsp_venv_paths(pkg)
	if
		vim.fn.executable(paths.python) ~= 1
		or vim.fn.executable(paths.black) ~= 1
		or vim.fn.executable(paths.ruff) ~= 1
	then
		return false
	end

	local res = vim.system({
		paths.python,
		"-c",
		"import importlib.metadata as m; [m.version(p) for p in ('python-lsp-black', 'python-lsp-ruff', 'pylsp-rope')]",
	}, {
		cwd = paths.venv,
		env = { VIRTUAL_ENV = paths.venv },
		text = true,
	}):wait(15000)

	return res.code == 0
end

local function install_pylsp_plugins(pkg)
	if pylsp_state.job then
		pylsp_state.pending = true
		pylsp_state.rerun = true
		pylsp_state.rerun_pkg = pkg
		return
	end

	local is_headless = #vim.api.nvim_list_uis() == 0
	local paths = get_pylsp_venv_paths(pkg)

	if vim.fn.executable(paths.python) ~= 1 then
		pylsp_state.pending = false
		pylsp_state.last_ok = false
		pylsp_state.last_err = "python executable not found in Mason python-lsp-server venv: " .. paths.python
		if is_headless then
			vim.api.nvim_err_writeln("[lsp] " .. pylsp_state.last_err)
		else
			vim.notify(pylsp_state.last_err, vim.log.levels.ERROR, { title = "[lsp] Install Failure" })
		end
		return
	end

	pylsp_state.pending = true
	pylsp_state.last_ok = nil
	pylsp_state.last_err = nil

	if not is_headless then
		vim.notify(
			"Now installing pylsp plugins...",
			vim.log.levels.INFO,
			{ title = "[lsp] Install Status", timeout = 6000 }
		)
	end

	local args = {
		paths.python,
		"-m",
		"pip",
		"install",
		"-U",
		"--no-user",
		"--disable-pip-version-check",
	}
	vim.list_extend(args, PYLSP_PLUGINS)

	pylsp_state.job = vim.system(
		args,
		{
			cwd = paths.venv,
			env = { VIRTUAL_ENV = paths.venv },
			text = true,
		},
		vim.schedule_wrap(function(res)
			pylsp_state.job = nil
			if pylsp_state.rerun then
				local next_pkg = pylsp_state.rerun_pkg
				pylsp_state.rerun = false
				pylsp_state.rerun_pkg = nil
				install_pylsp_plugins(next_pkg)
				return
			end

			local ok = res.code == 0 and are_pylsp_plugins_installed(pkg)
			pylsp_state.pending = false
			pylsp_state.last_ok = ok

			if ok then
				pylsp_state.last_err = nil
				if not is_headless then
					vim.notify(
						"Finished installing pylsp plugins",
						vim.log.levels.INFO,
						{ title = "[lsp] Install Status" }
					)
				end
			else
				local detail = vim.trim((res.stderr and res.stderr ~= "" and res.stderr) or (res.stdout or ""))
				if detail == "" then
					detail = "pip exited with code " .. tostring(res.code)
				end
				pylsp_state.last_err = detail
				if is_headless then
					vim.api.nvim_err_writeln("Failed to install pylsp plugins: " .. detail)
				else
					vim.notify(
						"Failed to install pylsp plugins.\n" .. detail,
						vim.log.levels.ERROR,
						{ title = "[lsp] Install Failure" }
					)
				end
			end
		end)
	)
end

local function wait_pylsp_install(timeout_ms)
	if not pylsp_state.pending and not pylsp_state.job then
		return true
	end
	local finished = vim.wait(timeout_ms or 300000, function()
		return not pylsp_state.pending and pylsp_state.job == nil
	end, 50)
	if not finished then
		pylsp_state.last_ok = false
		pylsp_state.last_err = "Timed out waiting for pylsp plugins installation"
		vim.api.nvim_err_writeln(pylsp_state.last_err)
		return false
	end
	return pylsp_state.last_ok ~= false
end

if not pylsp_state.hook_registered then
	pylsp_state.hook_registered = true
	require("mason-registry"):on("package:install:success", function(pkg)
		if not pkg or pkg.name ~= "python-lsp-server" then
			return
		end
		pylsp_state.pending = true
		vim.schedule(function()
			install_pylsp_plugins(pkg)
		end)
	end)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("UserMasonPylspWait", { clear = true }),
		callback = function()
			if #vim.api.nvim_list_uis() == 0 and not wait_pylsp_install(300000) then
				vim.cmd("1cq")
			end
		end,
	})
end

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

		local ok_pylsp, raw_pylsp_pkg = pcall(registry.get_package, "python-lsp-server")
		local pylsp_pkg = ok_pylsp and raw_pylsp_pkg or nil
		local pylsp_installing_before = pylsp_pkg ~= nil and pylsp_pkg.is_installing and pylsp_pkg:is_installing()

		local seen = {}
		local missing = {}
		for _, pkg in ipairs(candidates) do
			if pkg and not seen[pkg] then
				seen[pkg] = true
				if registry.has_package(pkg) then
					if pkg == "python-lsp-server" then
						if not pylsp_installing_before then
							local has_venv_py = registry.is_installed(pkg)
								and vim.fn.executable(get_pylsp_venv_paths(pylsp_pkg).python) == 1
							if not has_venv_py then
								table.insert(missing, pkg)
							end
						end
					elseif not registry.is_installed(pkg) then
						table.insert(missing, pkg)
					end
				end
			end
		end

		local installing_pylsp = vim.list_contains(missing, "python-lsp-server")
		if #missing > 0 then
			local prefix = #vim.api.nvim_list_uis() == 0 and "MasonInstall --quiet " or "MasonInstall "
			vim.cmd(prefix .. table.concat(missing, " "))
		end

		local wants_pylsp = vim.list_contains(settings.lsp_deps or {}, "pylsp")
		local pylsp_installing_now = pylsp_pkg ~= nil and pylsp_pkg.is_installing and pylsp_pkg:is_installing()
		if
			wants_pylsp
			and not installing_pylsp
			and not pylsp_installing_now
			and registry.is_installed("python-lsp-server")
		then
			if not are_pylsp_plugins_installed(pylsp_pkg) then
				install_pylsp_plugins(pylsp_pkg)
			end
		end

		if #vim.api.nvim_list_uis() == 0 then
			if wants_pylsp and pylsp_installing_now then
				local settled = false
				local install_ok = false
				if pylsp_pkg.once then
					pylsp_pkg:once("install:success", function()
						settled = true
						install_ok = true
					end)
					pylsp_pkg:once("install:failed", function()
						settled = true
						install_ok = false
					end)
				end
				local done = vim.wait(300000, function()
					if settled then
						return not install_ok or pylsp_state.pending or pylsp_state.job ~= nil
					end
					return not pylsp_pkg:is_installing() and (pylsp_state.pending or pylsp_state.job ~= nil)
				end, 50)
				if not done or (settled and not install_ok) then
					vim.api.nvim_err_writeln(
						not done and "Timed out waiting for Mason python-lsp-server installation"
							or "Mason python-lsp-server installation failed"
					)
					vim.cmd("1cq")
					return
				end
			end
			if not wait_pylsp_install(300000) then
				vim.cmd("1cq")
				return
			end
			if wants_pylsp and pylsp_installing_before and not are_pylsp_plugins_installed(pylsp_pkg) then
				vim.api.nvim_err_writeln("python-lsp-server installation failed before pylsp plugins could install")
				vim.cmd("1cq")
			end
		end
	end, { desc = "Install all configured Mason packages" })
end

return {
	max_concurrent_installers = 30,
}
