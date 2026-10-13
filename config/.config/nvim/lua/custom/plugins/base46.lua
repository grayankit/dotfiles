-- Dynamic colorscheme driven by DankMaterialShell's matugen Neovim template.
--
-- The `dms` colorscheme itself lives in ~/.config/nvim/colors/dms.lua (a
-- user-config file DMS regenerates on every wallpaper change), so lazy.nvim
-- cannot map `:colorscheme dms` back to this plugin. base46 therefore has to
-- be loaded eagerly, otherwise colors/dms.lua's `require("base46")` fails.
-- Setting the colorscheme inside this spec's own config also makes the load
-- order irrelevant to the other startup plugins.
return {
	"AvengeMedia/base46",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		-- colors/dms.lua is generated on the first matugen run and gitignored,
		-- so a fresh stow has no file yet. A bare colorscheme command errors.
		pcall(vim.cmd.colorscheme, "dms")
	end,
}
