return {
	"kawre/leetcode.nvim",
	cmd = "Leet",
	build = ":TSUpdate html",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-telescope/telescope.nvim",
	},
	opts = {
		lang = "cpp",
		plugins = {
			non_standalone = true,
		},
	},
}