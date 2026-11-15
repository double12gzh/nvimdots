local merged = vim.tbl_extend(
	"force",
	require("user.keymap.core"),
	require("user.keymap.completion").plug_map,
	require("user.keymap.editor"),
	require("user.keymap.lang"),
	require("user.keymap.tool"),
	require("user.keymap.ui")
)

local active = {}
for key, value in pairs(merged) do
	if value == "" or value == false then
		local modes, lhs = key:match("([^|]*)|?(.*)")
		for _, m in ipairs(vim.split(modes, "")) do
			if m ~= "" then
				pcall(vim.api.nvim_buf_del_keymap, 0, m, lhs)
				pcall(vim.api.nvim_del_keymap, m, lhs)
			end
		end
	elseif type(value) == "table" then
		active[key] = value
	end
end

require("keymap.bind").nvim_load_mapping(active)

return {}
