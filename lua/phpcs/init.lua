local M = {};

local phpcs_path = "/home/praem90/.config/composer/vendor/bin/phpcs"
local phpcbf_path =	"/home/praem90/.config/composer/vendor/bin/phpcbf"
local phpcs_standard = "PSR2"

function backticks_table(cmd)
	local tab = {}
	local pipe = assert(io.popen(cmd),
		"backticks_table(" .. cmd .. ") failed.")
	local line = pipe:read("*line")
	while line do
		table.insert(tab, line)
		line = pipe:read("*line")
	end
	return tab
end


M.cs = function ()
	local cmd = {
		phpcs_path,
		"--standard=" .. phpcs_standard,
		vim.fn.expand('%')
	}
	local output = backticks_table(table.concat(cmd, " "))

	print(table.concat(output, "\n"))

end


M.cbf = function ()
	local phpcs = {
		phpcbf_path,
		"--standard=" .. phpcs_standard,
		vim.fn.expand('%')
	}
	output = backticks_table(table.concat(phpcs, " "))
	vim.cmd('e')
end



return M
