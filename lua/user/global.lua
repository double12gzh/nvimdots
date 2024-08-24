local global = {}

function global:load_variables()
	self.proxy_nvim = os.getenv("PROXY_NVIM") or "http://127.0.0.1:7890"
end

global:load_variables()

return global
