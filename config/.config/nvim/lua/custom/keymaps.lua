vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp" },
	callback = function()
		vim.keymap.set("n", "<F5>", function()
			vim.cmd("w") -- Save the file

			local ft = vim.bo.filetype
			-- Use gcc for C files, g++ for C++ files
			local compiler = (ft == "c") and "gcc" or "g++"

			local file = vim.fn.expand("%")
			local out = vim.fn.expand("%:r")

			-- We wrap the command in bash -c '...' to handle the && and ; logic safely
			-- 1. Compile with warnings (-Wall)
			-- 2. If successful (&&), run the output
			-- 3. Always (;), pause at the end so you can read the output
			local shell_cmd = string.format(
				'bash -c "%s %s -o %s -Wall && ./%s; echo; read -p "Press Enter to exit...""',
				compiler,
				file,
				out,
				out
			)

			-- Open split and run the command
			vim.cmd("split | term " .. shell_cmd)
			vim.cmd("startinsert") -- Automatically switch to insert mode
		end, { buffer = true, desc = "Compile and run C/C++" })
	end,
})
