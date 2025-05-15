vim.api.nvim_create_autocmd("FileType", {
	pattern = "cpp",
	callback = function()
		vim.keymap.set("n", "<F5>", function()
			vim.cmd("w") -- Save the file
			local file = vim.fn.expand("%")
			local out = vim.fn.expand("%:r")
			vim.cmd("split | terminal g++ " .. file .. " -o " .. out .. " && ./" .. out)
		end, { buffer = true, desc = "Compile and run C++ file" })
	end,
})
