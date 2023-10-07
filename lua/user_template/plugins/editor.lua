local custom = {}

custom["folke/todo-comments.nvim"] = {
	lazy = true,
	event = "BufRead",
	config = require("user.configs.editor.todo-comments"), -- Require that config
}

return custom
