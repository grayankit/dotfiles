return {
	{
		"windwp/nvim-ts-autotag",
		ft = { "html", "javascript", "typescript", "vue", "svelte", "astro", "typescriptreact", "javascriptreact" },
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
}
