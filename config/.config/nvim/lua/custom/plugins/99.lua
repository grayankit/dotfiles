return {
	"ThePrimeagen/99",
	config = function()
		local _99 = require("99")

		local cwd = vim.uv.cwd()
		local basename = vim.fs.basename(cwd)

		_99.setup({
			logger = {
				level = _99.DEBUG,
				path = "/tmp/" .. basename .. ".99.debug",
				print_on_error = true,
			},
			completion = {
				source = "cmp",
			},
			md_files = {
				"AGENT.md",
			},
		})

		-- Visual mode: send selection + prompt to AI
		vim.keymap.set("v", "<leader>9v", function()
			_99.visual()
		end, { desc = "[99] Visual replace" })

		-- Cancel all in-flight requests
		vim.keymap.set("n", "<leader>9x", function()
			_99.stop_all_requests()
		end, { desc = "[99] Stop all requests" })

		-- Search across project with AI
		vim.keymap.set("n", "<leader>9s", function()
			_99.search()
		end, { desc = "[99] Search" })

		-- Open last interaction results
		vim.keymap.set("n", "<leader>9o", function()
			_99.open()
		end, { desc = "[99] Open last results" })

		-- View logs
		vim.keymap.set("n", "<leader>9l", function()
			_99.view_logs()
		end, { desc = "[99] View logs" })

		-- Telescope: switch model
		vim.keymap.set("n", "<leader>9m", function()
			require("99.extensions.telescope").select_model()
		end, { desc = "[99] Select model" })

		-- Telescope: switch provider
		vim.keymap.set("n", "<leader>9p", function()
			require("99.extensions.telescope").select_provider()
		end, { desc = "[99] Select provider" })
	end,
}
