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
		vim.cmd.colorscheme("dms")
	end,
}
