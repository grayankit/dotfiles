return {
	"NvChad/nvim-colorizer.lua",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("colorizer").setup({
			filetypes = {
				"*", -- Highlight all filetypes
				css = { css = true },
				html = { names = true },
			},
			user_default_options = {
				names = true,
				rgb_fn = true,
				hsl_fn = true,
				mode = "background", -- or 'foreground' / 'virtualtext'
			},
		})
	end,
}
