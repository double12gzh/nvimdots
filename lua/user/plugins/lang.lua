local lang = {}

-- Avoid running `lang.rust` in `init` on every Neovim startup (which eagerly loads
-- `rustaceanvim`, `blink.cmp`, `copilot.lua`, `LuaSnip`, and spawns `rustup`).
-- Running it in `config` ensures it executes lazily right before `rustaceanvim`'s
-- `ftplugin/rust.lua` when a Rust buffer is actually opened.
lang["mrcjkb/rustaceanvim"] = {
	init = false,
	config = function()
		require("lang.rust")()
	end,
}

return lang
