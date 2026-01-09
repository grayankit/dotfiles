return {
	{
		"michaelrommel/nvim-silicon",
		lazy = true,
		cmd = "Silicon",
		opts = {
			-- Configuration options
			font = "FiraCode Nerd Font",
			theme = "Monokai Extended",
			-- Note: The option is named 'to_clipboard' in this plugin, not 'clipboard'
			to_clipboard = true,
		},
		config = function(_, opts)
			-- IMPORTANT: This plugin uses the module name 'nvim-silicon', not 'silicon'
			require("nvim-silicon").setup(opts)
		end,
	},
}
