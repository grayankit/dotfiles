vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp" },
	callback = function()
		vim.keymap.set("n", "<F5>", function()
			vim.cmd("w")

			local ft = vim.bo.filetype
			local file = vim.fn.expand("%")
			local out = vim.fn.expand("%:r")

			local compile_cmd

			if ft == "c" then
				compile_cmd = string.format("gcc %s -Wall -Wextra -lm -o %s", file, out)
			else
				compile_cmd = string.format("g++ %s -Wall -Wextra -o %s", file, out)
			end

			local shell_cmd =
				string.format('bash -c "%s && ./%s; echo; read -p \\"Press Enter to exit...\\""', compile_cmd, out)

			vim.cmd("split | term " .. shell_cmd)
			vim.cmd("startinsert")
		end, { buffer = true, desc = "Compile and run C/C++" })
	end,
})
