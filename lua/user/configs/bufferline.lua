local icons = { ui = require("modules.utils.icons").get("ui") }
local default_icon_set = false

return {
	options = {
		numbers = "ordinal",
		modified_icon = icons.ui.Modified,
		color_icons = true,
		show_close_icon = true,
		enforce_regular_tabs = true,
		persist_buffer_sort = true,
		get_element_icon = function(buf)
			local devicons = require("nvim-web-devicons")
			if not default_icon_set then
				devicons.set_default_icon("", "#6d8086", 65)
				default_icon_set = true
			end
			return devicons.get_icon(buf.filetype, { default = true })
		end,
		offsets = function()
			return {
				{
					filetype = "NvimTree",
					text = "File Explorer",
					text_align = "center",
					padding = 1,
				},
				{
					filetype = "lspsagaoutline",
					text = "Lspsaga Outline",
					text_align = "center",
					padding = 1,
				},
				{
					filetype = "trouble",
					text = "LSP Outline",
					text_align = "center",
					padding = 1,
				},
			}
		end,
	},
}
