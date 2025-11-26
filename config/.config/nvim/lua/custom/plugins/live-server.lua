return {
	{
		"barrett-ruth/live-server.nvim",
		build = "bun install --global live-server",
		cmd = { "LiveServerStart", "LiveServerStop" },
		config = true,
	},
}
