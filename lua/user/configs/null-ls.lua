---Return formatter args required by `extra_args`.
---@param formatter_name string
---@return table|nil
local function formatter_args(formatter_name)
	local ok, args = pcall(require, "user.configs.formatters." .. formatter_name)
	if not ok then
		args = require("completion.formatters." .. formatter_name)
	end
	return args
end

return {
	sources = function()
		local btns = require("null-ls").builtins
		return {
			btns.formatting.clang_format.with({
				filetypes = { "c", "cpp", "objc", "objcpp", "cs", "cuda", "proto" },
				extra_args = formatter_args("clang_format"),
			}),
			btns.formatting.prettier.with({
				filetypes = {
					"vue",
					"typescript",
					"javascript",
					"typescriptreact",
					"javascriptreact",
					"yaml",
					"html",
					"css",
					"scss",
					"markdown",
				},
			}),
		}
	end,
}
