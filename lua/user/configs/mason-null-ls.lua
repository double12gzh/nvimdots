return {
	handlers = function(handlers)
		handlers = type(handlers) == "table" and handlers or {}
		handlers.gofumpt = function() end
		return handlers
	end,
}
