return {
	{
		"andweeb/presence.nvim",
		lazy = false,
		opts = {
			workspace_text = function()
				return "" -- leave workspace blank
			end,

			editing_text = function()
				local ft = vim.bo.filetype or "code"
				ft = ft:gsub("^%l", string.upper)
				return "Coding in " .. ft
			end,

			file_explorer_text = function()
				local ft = vim.bo.filetype or "code"
				ft = ft:gsub("^%l", string.upper)
				return "Exploring " .. ft .. " files"
			end,
		},
	},
	{ "wakatime/vim-wakatime", lazy = false },
}
